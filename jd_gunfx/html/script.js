(() => {
    'use strict';

    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    const ctx = new AudioCtx();

    let cfg = null;
    let ringBuffer = null;
    const whizBuffers = [];

    // ringing state
    let ringSource = null;
    let ringGain = null;
    let level = 0;
    let endAt = 0;
    let releaseTimer = 0;
    let stopTimer = 0;

    const clamp = (v, lo, hi) => Math.min(hi, Math.max(lo, v));

    async function load(url) {
        try {
            const res = await fetch(url);
            if (!res.ok) return null;
            return await ctx.decodeAudioData(await res.arrayBuffer());
        } catch (e) {
            return null;
        }
    }

    async function configure(data) {
        cfg = data;
        ringBuffer = await load('sounds/' + cfg.ringing.file);
        whizBuffers.length = 0;
        for (const name of cfg.whiz || []) {
            const buf = await load('sounds/' + name);
            if (buf) whizBuffers.push(buf);
        }
    }

    function wake() {
        if (ctx.state === 'suspended') ctx.resume();
    }

    /* ---------- ringing ---------- */

    function stopRing() {
        if (ringSource) {
            try { ringSource.stop(); } catch (e) {}
            ringSource.disconnect();
            ringSource = null;
        }
        if (ringGain) { ringGain.disconnect(); ringGain = null; }
        level = 0;
    }

    function release() {
        if (!ringGain) return;
        const fade = Math.max(200, cfg.ringing.fadeOut);
        ringGain.gain.cancelScheduledValues(ctx.currentTime);
        ringGain.gain.setValueAtTime(ringGain.gain.value, ctx.currentTime);
        ringGain.gain.setTargetAtTime(0, ctx.currentTime, fade / 4000);
        level = 0;
        clearTimeout(stopTimer);
        stopTimer = setTimeout(stopRing, fade + 150);
    }

    function ring(volume, duration) {
        if (!cfg || !ringBuffer) return;
        wake();

        clearTimeout(stopTimer);
        const r = cfg.ringing;
        level = level > 0
            ? clamp(level + volume * r.stack, 0, r.maxVolume)
            : clamp(volume, 0, r.maxVolume);

        if (!ringSource) {
            ringGain = ctx.createGain();
            ringGain.gain.value = 0;
            ringSource = ctx.createBufferSource();
            ringSource.buffer = ringBuffer;
            ringSource.loop = !!r.loop;
            ringSource.connect(ringGain);
            ringGain.connect(ctx.destination);
            ringSource.onended = () => { if (ringSource && !r.loop) { stopRing(); } };
            ringSource.start(0);
        }

        const target = level * r.volume;
        ringGain.gain.cancelScheduledValues(ctx.currentTime);
        ringGain.gain.setTargetAtTime(target, ctx.currentTime, 0.04);

        endAt = Math.max(endAt, Date.now() + duration);
        clearTimeout(releaseTimer);
        releaseTimer = setTimeout(release, Math.max(0, endAt - Date.now()));
    }

    /* ---------- bullet whizz ---------- */

    function whiz(volume) {
        if (!whizBuffers.length) return;
        wake();

        const src = ctx.createBufferSource();
        src.buffer = whizBuffers[(Math.random() * whizBuffers.length) | 0];
        src.playbackRate.value = 0.92 + Math.random() * 0.16;

        const gain = ctx.createGain();
        gain.gain.value = clamp(volume, 0, 1);

        const pan = ctx.createStereoPanner ? ctx.createStereoPanner() : null;
        if (pan) {
            pan.pan.value = (Math.random() * 1.6) - 0.8;
            src.connect(pan);
            pan.connect(gain);
        } else {
            src.connect(gain);
        }
        gain.connect(ctx.destination);
        src.onended = () => { src.disconnect(); gain.disconnect(); if (pan) pan.disconnect(); };
        src.start(0);
    }

    /* ---------- messages ---------- */

    window.addEventListener('message', (e) => {
        const d = e.data;
        if (!d || !d.action) return;
        if (d.action === 'config') configure(d);
        else if (d.action === 'ring') ring(+d.volume || 0, +d.duration || 2000);
        else if (d.action === 'whiz') whiz(+d.volume || 0.6);
    });

    fetch(`https://${GetParentResourceName()}/ready`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: '{}'
    }).catch(() => {});
})();
