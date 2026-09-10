// typing_pop: a short ring that pops at the cursor on every cursor move.
// Adapted from ripple_cursor.glsl (github.com/hackr-sh/ghostty-shaders) with the
// trigger changed from "cursor width changed" (vim mode switch) to "cursor moved
// at all", so it fires while typing and not on focus changes. The ring expands
// past the cursor cell, so unlike a trail it is never hidden behind the cursor
// box on single-char moves.

// CONFIGURATION
const float DURATION = 0.15;               // How long the pop animates (seconds)
const float MAX_RADIUS = 0.05;             // Max radius in normalized coords (~1 cell height)
const float RING_THICKNESS = 0.02;         // Ring width in normalized coords
const float MOVE_EPSILON = 0.0001;         // Below this distance the cursor counts as not moved
vec4 COLOR = vec4(1.0, 0.725, 0.161, 1.0); // yellow, matches cursor_blaze TRAIL_COLOR
const float BLUR = 3.0;                    // Blur level in pixels
const float ANIMATION_START_OFFSET = 0.0;  // Start the pop slightly progressed (0.0 - 1.0)


// Easing functions
float easeOutQuad(float t) {
    return 1.0 - (1.0 - t) * (1.0 - t);
}
float easeInOutQuad(float t) {
    return t < 0.5 ? 2.0 * t * t : 1.0 - pow(-2.0 * t + 2.0, 2.0) / 2.0;
}
float easeOutCubic(float t) {
    return 1.0 - pow(1.0 - t, 3.0);
}
float easeOutQuart(float t) {
    return 1.0 - pow(1.0 - t, 4.0);
}
float easeOutQuint(float t) {
    return 1.0 - pow(1.0 - t, 5.0);
}
float easeOutExpo(float t) {
    return t == 1.0 ? 1.0 : 1.0 - pow(2.0, -10.0 * t);
}
float easeOutCirc(float t) {
    return sqrt(1.0 - pow(t - 1.0, 2.0));
}
float easeOutSine(float t) {
    return sin((t * 3.1415916) / 2.0);
}
float easeOutElastic(float t) {
    const float c4 = (2.0 * 3.1415916) / 3.0;
    return t == 0.0 ? 0.0 : t == 1.0 ? 1.0 : pow(2.0, -10.0 * t) * sin((t * 10.0 - 0.75) * c4) + 1.0;
}
float easeOutBack(float t) {
    const float c1 = 1.70158;
    const float c3 = c1 + 1.0;
    return 1.0 + c3 * pow(t - 1.0, 3.0) + c1 * pow(t - 1.0, 2.0);
}

// Pulse fade functions
float easeOutPulse(float t) {
    return t * (2.0 - t);
}
float exponentialDecayPulse(float t) {
    return exp(-3.0 * t) * sin(t * 3.1415916);
}

vec2 normalize(vec2 value, float isPosition) {
    return (value * 2.0 - (iResolution.xy * isPosition)) / iResolution.y;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord){
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    // Normalization & setup (-1 to 1 coords)
    vec2 vu = normalize(fragCoord, 1.);
    vec2 offsetFactor = vec2(-.5, 0.5);

    vec4 currentCursor = vec4(normalize(iCurrentCursor.xy, 1.), normalize(iCurrentCursor.zw, 0.));
    vec4 previousCursor = vec4(normalize(iPreviousCursor.xy, 1.), normalize(iPreviousCursor.zw, 0.));

    vec2 centerCC = currentCursor.xy - (currentCursor.zw * offsetFactor);

    // TRIGGER: pop when the cursor moved anywhere, including a single cell while
    // typing. No distance threshold, unlike cursor_blaze's DRAW_THRESHOLD.
    // Deliberately NOT gated on cursor width change: unfocusing the window swaps the
    // cursor from filled block to hollow, which would start a pop at the same moment
    // Ghostty halts the shader animation loop (custom-shader-animation = true only
    // animates while focused), freezing the ring on screen until refocus.
    float isTriggered = step(MOVE_EPSILON, distance(currentCursor.xy, previousCursor.xy));

    // ANIMATION
    float rippleProgress = (iTime - iTimeCursorChange) / DURATION + ANIMATION_START_OFFSET;
    // don't clamp yet; we need to know if it's > 1.0 (finished)
    float isAnimating = 1.0 - step(1.0, rippleProgress); // progress < 1.0 ? 1.0: 0.0

    // iFocus guard: iTime is "seconds since first frame rendered", so it nearly stops
    // advancing while the surface is unfocused (the animation loop only runs when
    // focused). An isolated "deceptive frame" while unfocused -- a modifier keypress,
    // a link hover -- can therefore render with iTime - iTimeCursorChange still inside
    // [0, DURATION), painting a stale ring that then freezes on screen until refocus.
    // Ghostty exposes iFocus specifically to suppress this class of artifact.
    if (isTriggered > 0.0 && isAnimating > 0.0 && iFocus > 0) {
        // Apply easing to progress
        // float easedProgress = easeOutQuad(rippleProgress);
        // float easedProgress = easeOutCubic(rippleProgress);
        // float easedProgress = easeOutExpo(rippleProgress);
        float easedProgress = easeOutCirc(rippleProgress);
        // float easedProgress = easeOutBack(rippleProgress);

        // RIPPLE CALCULATION
        float rippleRadius = easedProgress * MAX_RADIUS;

        // float fade = 1.0 - easedProgress; // linear fade
        float fade = 1.0 - easeOutPulse(rippleProgress);
        // float fade = 1.0 - exponentialDecayPulse(rippleProgress);

        // Calculate distance from frag to cursor center
        float dist = distance(vu, centerCC);

        float sdfRing = abs(dist - rippleRadius) - RING_THICKNESS * 0.5;

        // Antialias (1-pixel width in normalized coords)
        float antiAliasSize = normalize(vec2(BLUR, BLUR), 0.0).x;
        float ripple = (1.0 - smoothstep(-antiAliasSize, antiAliasSize, sdfRing)) * fade;

        // Apply ripple effect
        fragColor = mix(fragColor, COLOR, ripple * COLOR.a);
    }
    // else: do nothing, keep original fragColor
}
