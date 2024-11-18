#ifndef SSR_INC
#define SSR_INC

group_uniforms SSR;
	uniform float ssrIntensity:hint_range(0, 1) = 0.5;
	uniform sampler2D ssrIntensityTexture:hint_default_white;
	uniform float ssrMaxDistance = 15.0;
	uniform int ssrMaxGuessSteps:hint_range(1, 1000) = 100;
	uniform int ssrCorrectionSteps:hint_range(1, 1000) = 10;
	uniform float ssrThickness = 0.5;
group_uniforms;

uniform sampler2D SSR_SCREEN_TEXTURE:hint_screen_texture, filter_linear, repeat_disable;
uniform sampler2D SSR_DEPTH_TEXTURE:hint_depth_texture, filter_linear, repeat_disable;

#define applySSR(color) ssr(\
	(color), NORMAL, VERTEX, UV, PROJECTION_MATRIX, OUTPUT_IS_SRGB, SSR_SCREEN_TEXTURE, SSR_DEPTH_TEXTURE \
)

vec3 ssr(vec3 ssrAlbedo, vec3 ssrNormal, vec3 ssrVertex, vec2 ssrUv,mat4 ssrProjectionMatrix, bool ssrIsOpenGL,
	sampler2D ssrScreenTexture, sampler2D ssrDepthTexture) {

	#ifndef depthBufferToDepth
	#define depthBufferToDepth(buf, near_inv, far_inv)  (-1.0 / max(far_inv + buf * (near_inv - far_inv), 0.001))
	#endif

	float NEAR = ssrProjectionMatrix[3][2] / (ssrProjectionMatrix[2][2] + 1.0);
	float FAR = ssrProjectionMatrix[3][2] / (ssrProjectionMatrix[2][2] - (ssrIsOpenGL ? 1.0 : 0.0));
	float NEAR_INV = 1.0 / NEAR;
	float FAR_INV = 1.0 / FAR;

	vec2 screenSize = vec2(textureSize(ssrScreenTexture, 0));

	vec3 pivot = normalize(reflect(ssrVertex, ssrNormal));

	vec4 startView = vec4(ssrVertex, 1);
	vec4 endView = vec4(ssrVertex + pivot * ssrMaxDistance, 1);

	vec4 startFrag = ssrProjectionMatrix * startView;
	startFrag.xyz /= startFrag.w;
	startFrag = startFrag * 0.5 + 0.5;
	vec4 endFrag = ssrProjectionMatrix * endView;
	endFrag.xyz /= endFrag.w;
	endFrag = endFrag * 0.5 + 0.5;


	float deltaX = endFrag.x - startFrag.x;
	float deltaY = endFrag.y - startFrag.y;
	float useX = abs(deltaX) >= abs(deltaY) ? 1.0 : 0.0;
	float delta = mix(abs(deltaY) * screenSize.y, abs(deltaX) * screenSize.x, useX);
	vec2 increment = vec2(deltaX, deltaY) / clamp(delta, 0.001, float(ssrMaxGuessSteps));

	float search0 = 0.0;
	float search1 = 0.0;
	int hit0 = 0;
	int hit1 = 0;

	vec2 frag = startFrag.xy;
	float depth = ssrThickness;
	float depthTo;
	bool active = true;

	for (int i = 0; i < min(int(delta), ssrMaxGuessSteps); ++i) {
		frag += increment * float(active);
		depthTo = active ? textureLod(ssrDepthTexture, frag, 0.0).r : depthTo;
		depthTo = active ? depthBufferToDepth(depthTo, NEAR_INV, FAR_INV) : depthTo;

		search1 = active ? mix(
			(frag.y - startFrag.y) / deltaY,
			(frag.x - startFrag.x) / deltaX,
			useX
		) : search1;
		float viewDistance = (startView.z * endView.z) / mix(endView.z, startView.z, search1);
		depth = active ? viewDistance - depthTo : depth;
		if (depth < 0.0 && depth > -ssrThickness) {
			hit0 = 1;
			active = false;
		} else {
			search0 = active ? search1 : search0;
		}
	}
	search1 = search0 + ((search1 - search0) * 0.5);

	int currentSteps = ssrCorrectionSteps * hit0;
	for (int i = 0; i < currentSteps; ++i) {
		frag = mix(startFrag.xy, endFrag.xy, search1);
		depthTo = textureLod(ssrDepthTexture, frag, 0.0).r;
		depthTo = depthBufferToDepth(depthTo, NEAR_INV, FAR_INV);
		float viewDistance = (startView.z * endView.z) / mix(endView.z, startView.z, search1);
		depth = viewDistance - depthTo;

		if (depth < 0.0 && depth > -ssrThickness) {
			hit1 = 1;
			search1 = search0 + ((search1 - search0) * 0.5);
		} else {
			float temp = search1;
			search1 = search1 + ((search1 - search0) * 0.5);
			search0 = temp;
		}
	}
	

	float visibility =
		float(hit1) *
		(1.0 - max(dot(-normalize(ssrVertex), pivot), 0.0)) *
		float(depthTo > -FAR + 1.0) *
		(1.0 - clamp(-depth / ssrThickness, 0.0, 1.0)) *
		(1.0 - max(clamp((depthTo - startView.z) / (endView.z - startView.z), 0.0, 1.0) * 5.0 - 4.0, 0.0)) *
		(1.0 - max(max(max(frag.x, frag.y) * 10.0 - 9.0, (1.0 - min(frag.x, frag.y)) * 10.0 - 9.0), 0.0)) *
		float(frag.x >= 0.0 && frag.x <= 1.0) *
		float(frag.y >= 0.0 && frag.y <= 1.0);
	visibility = clamp(visibility, 0.0, 1.0);

	vec3 resultColor = vec3(0.0);
	vec2 pixelSize = 1.0 / vec2(screenSize);
	for (int i = -1; i <= 1; ++i) {
		for (int j = -1; j <= 1; ++j) {
			resultColor += textureLod(ssrScreenTexture, frag + vec2(float(i), float(j)) * pixelSize, 0.0).rgb;
		}
	}
	resultColor /= 9.0;

	return mix(ssrAlbedo, resultColor, ssrIntensity * texture(ssrIntensityTexture, ssrUv).r * visibility);
}

#endif