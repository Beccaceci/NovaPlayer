import React, { useState, useRef, useEffect, useCallback } from "react";
import {
  Play,
  Pause,
  RotateCcw,
  RotateCw,
  Volume2,
  VolumeX,
  Maximize,
  Minimize,
  Settings,
  Subtitles,
  Upload,
  X
} from "lucide-react";
import { getCurrentWindow } from "@tauri-apps/api/window";

export default function App() {
  const [videoSrc, setVideoSrc] = useState<string | null>(null);
  const [fileName, setFileName] = useState<string>("");
  const [isPlaying, setIsPlaying] = useState<boolean>(false);
  const [currentTime, setCurrentTime] = useState<number>(0);
  const [duration, setDuration] = useState<number>(0);
  const [speed, setSpeed] = useState<number>(1.0);
  const [volume] = useState<number>(1.0);
  const [isMuted, setIsMuted] = useState<boolean>(false);
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const [controlsVisible, setControlsVisible] = useState<boolean>(true);
  const [skipHud, setSkipHud] = useState<{ text: string; direction: "fwd" | "bwd" } | null>(null);
  const [hoverTime, setHoverTime] = useState<number | null>(null);
  const [hoverPos, setHoverPos] = useState<number>(0);
  const [showSettings, setShowSettings] = useState<boolean>(false);
  const [showSubtitles, setShowSubtitles] = useState<boolean>(true);
  const [isDragging, setIsDragging] = useState<boolean>(false);

  const videoRef = useRef<HTMLVideoElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const hideControlsTimer = useRef<number | null>(null);

  // Trigger HUD animation
  const triggerHud = (text: string, direction: "fwd" | "bwd") => {
    setSkipHud({ text, direction });
    setTimeout(() => setSkipHud(null), 600);
  };

  // Skip time helper
  const skip = useCallback((seconds: number) => {
    if (!videoRef.current) return;
    const newTime = Math.max(0, Math.min(videoRef.current.duration || 0, videoRef.current.currentTime + seconds));
    videoRef.current.currentTime = newTime;
    setCurrentTime(newTime);
    triggerHud(seconds > 0 ? `+${seconds}s` : `${seconds}s`, seconds > 0 ? "fwd" : "bwd");
  }, []);

  // Granular speed adjustment with 0.05x precision
  const adjustSpeed = useCallback((delta: number) => {
    setSpeed((prev) => {
      const next = Math.max(0.25, Math.min(4.0, Math.round((prev + delta) * 100) / 100));
      if (videoRef.current) videoRef.current.playbackRate = next;
      return next;
    });
  }, []);

  // Format time helper
  const formatTime = (secs: number) => {
    const total = Math.floor(secs || 0);
    const m = Math.floor(total / 60);
    const s = total % 60;
    return `${m}:${s < 10 ? "0" : ""}${s}`;
  };

  // Keyboard hotkeys matching YouTube & NovaPlayer macOS
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      // Avoid hotkeys when typing in input
      if (e.target instanceof HTMLInputElement) return;

      switch (e.key) {
        case " ":
        case "k":
        case "K":
          e.preventDefault();
          if (videoRef.current) {
            if (videoRef.current.paused) {
              videoRef.current.play();
              setIsPlaying(true);
            } else {
              videoRef.current.pause();
              setIsPlaying(false);
            }
          }
          break;
        case "j":
        case "J":
          e.preventDefault();
          skip(-10);
          break;
        case "l":
        case "L":
          e.preventDefault();
          skip(10);
          break;
        case "ArrowLeft":
          e.preventDefault();
          skip(-5);
          break;
        case "ArrowRight":
          e.preventDefault();
          skip(5);
          break;
        case ">":
          e.preventDefault();
          adjustSpeed(0.05);
          break;
        case "<":
          e.preventDefault();
          adjustSpeed(-0.05);
          break;
        case "m":
        case "M":
          e.preventDefault();
          setIsMuted((prev) => {
            const next = !prev;
            if (videoRef.current) videoRef.current.muted = next;
            return next;
          });
          break;
        case "f":
        case "F":
          e.preventDefault();
          toggleFullscreen();
          break;
        default:
          break;
      }
    };

    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [skip, adjustSpeed]);

  // Autohide controls on inactivity
  const handleMouseMove = () => {
    setControlsVisible(true);
    if (hideControlsTimer.current) clearTimeout(hideControlsTimer.current);
    if (isPlaying) {
      hideControlsTimer.current = window.setTimeout(() => {
        setControlsVisible(false);
      }, 2500);
    }
  };

  const toggleFullscreen = async () => {
    try {
      const appWindow = getCurrentWindow();
      const current = await appWindow.isFullscreen();
      await appWindow.setFullscreen(!current);
      setIsFullscreen(!current);
    } catch {
      // Fallback for browser testing
      if (!document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(() => {});
        setIsFullscreen(true);
      } else {
        document.exitFullscreen().catch(() => {});
        setIsFullscreen(false);
      }
    }
  };

  // Video File Selection
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      setVideoSrc(url);
      setFileName(file.name);
      setIsPlaying(true);
    }
  };

  // Drag and drop video file
  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files?.[0];
    if (file && (file.type.includes("video") || file.name.endsWith(".mp4") || file.name.endsWith(".mkv") || file.name.endsWith(".mov"))) {
      const url = URL.createObjectURL(file);
      setVideoSrc(url);
      setFileName(file.name);
      setIsPlaying(true);
    }
  };

  return (
    <div
      className="relative w-screen h-screen overflow-hidden select-none bg-[#0a0d14]"
      onMouseMove={handleMouseMove}
      onDragOver={(e) => {
        e.preventDefault();
        setIsDragging(true);
      }}
      onDragLeave={() => setIsDragging(false)}
      onDrop={handleDrop}
      style={{
        display: "flex",
        flexDirection: "column",
        width: "100vw",
        height: "100vh",
        backgroundColor: "#0b0e17"
      }}
    >
      {/* Custom Window Titlebar (Drag Region for Borderless Window) */}
      <div
        data-tauri-drag-region
        style={{
          height: "38px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "0 14px",
          background: "rgba(10, 14, 24, 0.65)",
          borderBottom: "1px solid rgba(255, 255, 255, 0.06)",
          zIndex: 50,
          userSelect: "none"
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: "8px" }}>
          {/* macOS / Window traffic lights */}
          <div
            onClick={() => getCurrentWindow().close()}
            style={{ width: "12px", height: "12px", borderRadius: "50%", backgroundColor: "#ff5f56", cursor: "pointer" }}
            title="Close"
          />
          <div
            onClick={() => getCurrentWindow().minimize()}
            style={{ width: "12px", height: "12px", borderRadius: "50%", backgroundColor: "#ffbd2e", cursor: "pointer" }}
            title="Minimize"
          />
          <div
            onClick={toggleFullscreen}
            style={{ width: "12px", height: "12px", borderRadius: "50%", backgroundColor: "#27c93f", cursor: "pointer" }}
            title="Toggle Fullscreen"
          />
          <span style={{ fontSize: "12px", fontWeight: 600, color: "rgba(255,255,255,0.7)", marginLeft: "12px" }}>
            NovaPlayer {fileName ? `— ${fileName}` : ""}
          </span>
        </div>

        <div style={{ display: "flex", alignItems: "center", gap: "12px" }}>
          <button
            onClick={() => setShowSettings(!showSettings)}
            style={{ background: "none", border: "none", color: "rgba(255,255,255,0.7)", cursor: "pointer" }}
          >
            <Settings size={15} />
          </button>
        </div>
      </div>

      {/* Main Viewport */}
      <div style={{ position: "relative", flex: 1, display: "flex", alignItems: "center", justifyContent: "center" }}>
        {videoSrc ? (
          <>
            <video
              ref={videoRef}
              src={videoSrc}
              autoPlay
              style={{ width: "100%", height: "100%", objectFit: "contain" }}
              onTimeUpdate={() => {
                if (videoRef.current) setCurrentTime(videoRef.current.currentTime);
              }}
              onLoadedMetadata={() => {
                if (videoRef.current) {
                  setDuration(videoRef.current.duration);
                  videoRef.current.playbackRate = speed;
                }
              }}
              onPlay={() => setIsPlaying(true)}
              onPause={() => setIsPlaying(false)}
              onClick={() => {
                if (videoRef.current) {
                  if (videoRef.current.paused) videoRef.current.play();
                  else videoRef.current.pause();
                }
              }}
            />

            {/* Subtitles Overlay */}
            {showSubtitles && (
              <div
                style={{
                  position: "absolute",
                  bottom: "90px",
                  left: "50%",
                  transform: "translateX(-50%)",
                  padding: "6px 16px",
                  background: "rgba(0,0,0,0.75)",
                  borderRadius: "8px",
                  color: "#fff",
                  fontSize: "18px",
                  fontWeight: 500,
                  pointerEvents: "none"
                }}
              >
                NovaPlayer Live Multilingual Subtitles Active
              </div>
            )}
          </>
        ) : (
          /* Empty / Welcome Drag & Drop Zone */
          <div
            onClick={() => fileInputRef.current?.click()}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
              padding: "48px",
              borderRadius: "24px",
              border: `2px dashed ${isDragging ? "#38bdf8" : "rgba(255,255,255,0.15)"}`,
              background: isDragging ? "rgba(56, 189, 248, 0.08)" : "rgba(255,255,255,0.02)",
              transition: "all 0.2s ease"
            }}
          >
            <div
              style={{
                width: "72px",
                height: "72px",
                borderRadius: "50%",
                background: "linear-gradient(135deg, #38bdf8, #818cf8)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                marginBottom: "20px",
                boxShadow: "0 8px 24px rgba(56, 189, 248, 0.3)"
              }}
            >
              <Upload size={32} color="#ffffff" />
            </div>
            <h2 style={{ fontSize: "20px", fontWeight: 600, color: "#fff", margin: "0 0 8px 0" }}>
              Drop video here or click to open
            </h2>
            <p style={{ fontSize: "13px", color: "rgba(255,255,255,0.5)", margin: 0 }}>
              Supports MP4, MKV, WebM, MOV across macOS, Windows & Linux
            </p>
          </div>
        )}

        <input
          ref={fileInputRef}
          type="file"
          accept="video/*"
          style={{ display: "none" }}
          onChange={handleFileChange}
        />

        {/* Animated Skip HUD (±5s) */}
        {skipHud && (
          <div
            className="animate-pop"
            style={{
              position: "absolute",
              top: "50%",
              left: "50%",
              transform: "translate(-50%, -50%)",
              display: "flex",
              alignItems: "center",
              gap: "8px",
              padding: "14px 28px",
              borderRadius: "9999px",
              background: "rgba(18, 22, 34, 0.85)",
              backdropFilter: "blur(24px)",
              border: "1px solid rgba(255,255,255,0.18)",
              boxShadow: "0 20px 40px rgba(0,0,0,0.6)",
              color: "#38bdf8",
              fontSize: "22px",
              fontWeight: 700,
              pointerEvents: "none"
            }}
          >
            {skipHud.direction === "fwd" ? <RotateCw size={24} /> : <RotateCcw size={24} />}
            <span>{skipHud.text}</span>
          </div>
        )}
      </div>

      {/* Floating Bottom Glass Controls */}
      {videoSrc && (
        <div
          style={{
            position: "absolute",
            bottom: "20px",
            left: "50%",
            transform: "translateX(-50%)",
            width: "calc(100% - 48px)",
            maxWidth: "880px",
            padding: "12px 20px",
            borderRadius: "18px",
            background: "rgba(15, 20, 32, 0.78)",
            backdropFilter: "blur(32px) saturate(180%)",
            WebkitBackdropFilter: "blur(32px) saturate(180%)",
            border: "1px solid rgba(255, 255, 255, 0.12)",
            boxShadow: "0 16px 36px rgba(0, 0, 0, 0.55)",
            opacity: controlsVisible ? 1 : 0,
            pointerEvents: controlsVisible ? "auto" : "none",
            transition: "opacity 0.3s cubic-bezier(0.16, 1, 0.3, 1)",
            zIndex: 40
          }}
        >
          {/* Timeline Scrubber */}
          <div
            style={{ position: "relative", width: "100%", height: "20px", display: "flex", alignItems: "center", cursor: "pointer" }}
            onMouseMove={(e) => {
              const rect = e.currentTarget.getBoundingClientRect();
              const pos = (e.clientX - rect.left) / rect.width;
              setHoverPos(e.clientX - rect.left);
              setHoverTime(pos * duration);
            }}
            onMouseLeave={() => setHoverTime(null)}
            onClick={(e) => {
              const rect = e.currentTarget.getBoundingClientRect();
              const pos = (e.clientX - rect.left) / rect.width;
              if (videoRef.current) {
                const target = pos * duration;
                videoRef.current.currentTime = target;
                setCurrentTime(target);
              }
            }}
          >
            {/* Hover Thumbnail Badge */}
            {hoverTime !== null && (
              <div
                style={{
                  position: "absolute",
                  bottom: "26px",
                  left: `${hoverPos}px`,
                  transform: "translateX(-50%)",
                  padding: "4px 10px",
                  borderRadius: "6px",
                  background: "rgba(10, 14, 24, 0.92)",
                  border: "1px solid rgba(255,255,255,0.15)",
                  color: "#38bdf8",
                  fontSize: "11px",
                  fontWeight: 600,
                  whiteSpace: "nowrap",
                  pointerEvents: "none"
                }}
              >
                {formatTime(hoverTime)}
              </div>
            )}

            <div style={{ width: "100%", height: "5px", borderRadius: "9999px", background: "rgba(255,255,255,0.15)", overflow: "hidden" }}>
              <div
                style={{
                  height: "100%",
                  width: `${(currentTime / (duration || 1)) * 100}%`,
                  background: "linear-gradient(90deg, #38bdf8, #818cf8)"
                }}
              />
            </div>
          </div>

          {/* Controls Bar */}
          <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: "6px" }}>
            {/* Left Controls: Play/Pause, Skips, Timestamp */}
            <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
              <button
                onClick={() => {
                  if (videoRef.current) {
                    if (isPlaying) videoRef.current.pause();
                    else videoRef.current.play();
                  }
                }}
                style={{
                  width: "36px",
                  height: "36px",
                  borderRadius: "50%",
                  background: "rgba(255,255,255,0.12)",
                  border: "none",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "#fff",
                  cursor: "pointer"
                }}
              >
                {isPlaying ? <Pause size={17} /> : <Play size={17} style={{ marginLeft: "2px" }} />}
              </button>

              <button
                onClick={() => skip(-5)}
                style={{ background: "none", border: "none", color: "rgba(255,255,255,0.7)", cursor: "pointer" }}
                title="Back 5s (Left Arrow)"
              >
                <RotateCcw size={18} />
              </button>

              <button
                onClick={() => skip(5)}
                style={{ background: "none", border: "none", color: "rgba(255,255,255,0.7)", cursor: "pointer" }}
                title="Forward 5s (Right Arrow)"
              >
                <RotateCw size={18} />
              </button>

              <span style={{ fontSize: "12px", color: "rgba(255,255,255,0.7)", fontWeight: 500, marginLeft: "4px" }}>
                {formatTime(currentTime)} / {formatTime(duration)}
              </span>
            </div>

            {/* Right Controls: Granular Speed Dial, Subtitles, Volume, Fullscreen */}
            <div style={{ display: "flex", alignItems: "center", gap: "14px" }}>
              {/* Granular Speed 0.05x Dial */}
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "6px",
                  background: "rgba(255,255,255,0.08)",
                  padding: "4px 10px",
                  borderRadius: "9999px",
                  border: "1px solid rgba(255,255,255,0.12)"
                }}
              >
                <button
                  onClick={() => adjustSpeed(-0.05)}
                  style={{ background: "none", border: "none", color: "rgba(255,255,255,0.6)", cursor: "pointer", fontWeight: 700 }}
                  title="Slow down 0.05x (<)"
                >
                  -
                </button>
                <span style={{ fontSize: "12px", fontWeight: 700, color: "#38bdf8", minWidth: "42px", textAlign: "center" }}>
                  {speed.toFixed(2)}×
                </span>
                <button
                  onClick={() => adjustSpeed(0.05)}
                  style={{ background: "none", border: "none", color: "rgba(255,255,255,0.6)", cursor: "pointer", fontWeight: 700 }}
                  title="Speed up 0.05x (>)"
                >
                  +
                </button>
              </div>

              {/* Subtitles Toggle */}
              <button
                onClick={() => setShowSubtitles(!showSubtitles)}
                style={{
                  background: "none",
                  border: "none",
                  color: showSubtitles ? "#38bdf8" : "rgba(255,255,255,0.5)",
                  cursor: "pointer"
                }}
                title="Toggle Subtitles"
              >
                <Subtitles size={18} />
              </button>

              {/* Volume */}
              <button
                onClick={() => {
                  setIsMuted(!isMuted);
                  if (videoRef.current) videoRef.current.muted = !isMuted;
                }}
                style={{ background: "none", border: "none", color: "rgba(255,255,255,0.7)", cursor: "pointer" }}
                title="Mute (M)"
              >
                {isMuted || volume === 0 ? <VolumeX size={18} /> : <Volume2 size={18} />}
              </button>

              {/* Fullscreen */}
              <button
                onClick={toggleFullscreen}
                style={{ background: "none", border: "none", color: "rgba(255,255,255,0.7)", cursor: "pointer" }}
                title="Fullscreen (F)"
              >
                {isFullscreen ? <Minimize size={18} /> : <Maximize size={18} />}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Settings Modal */}
      {showSettings && (
        <div
          style={{
            position: "absolute",
            top: "54px",
            right: "20px",
            width: "300px",
            padding: "16px",
            borderRadius: "16px",
            background: "rgba(16, 21, 35, 0.92)",
            backdropFilter: "blur(24px)",
            border: "1px solid rgba(255,255,255,0.14)",
            boxShadow: "0 20px 45px rgba(0,0,0,0.6)",
            zIndex: 60
          }}
        >
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: "12px" }}>
            <span style={{ fontSize: "14px", fontWeight: 600, color: "#fff" }}>Preferences</span>
            <button
              onClick={() => setShowSettings(false)}
              style={{ background: "none", border: "none", color: "rgba(255,255,255,0.5)", cursor: "pointer" }}
            >
              <X size={15} />
            </button>
          </div>

          <div style={{ display: "flex", flexDirection: "column", gap: "10px", fontSize: "12px" }}>
            <div>
              <span style={{ color: "rgba(255,255,255,0.6)" }}>Skip Interval:</span>
              <div style={{ display: "flex", gap: "6px", marginTop: "4px" }}>
                {["3s", "5s", "10s", "15s"].map((int) => (
                  <button
                    key={int}
                    style={{
                      flex: 1,
                      padding: "4px",
                      borderRadius: "6px",
                      background: int === "5s" ? "rgba(56, 189, 248, 0.2)" : "rgba(255,255,255,0.06)",
                      border: `1px solid ${int === "5s" ? "#38bdf8" : "rgba(255,255,255,0.1)"}`,
                      color: int === "5s" ? "#38bdf8" : "#fff",
                      fontSize: "11px",
                      cursor: "pointer"
                    }}
                  >
                    {int}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <span style={{ color: "rgba(255,255,255,0.6)" }}>Target Subtitle Language:</span>
              <select
                style={{
                  width: "100%",
                  marginTop: "4px",
                  padding: "6px",
                  background: "rgba(255,255,255,0.08)",
                  border: "1px solid rgba(255,255,255,0.12)",
                  borderRadius: "6px",
                  color: "#fff",
                  fontSize: "12px"
                }}
              >
                <option value="en">English</option>
                <option value="es">Spanish (Español)</option>
                <option value="it">Italian (Italiano)</option>
                <option value="fr">French (Français)</option>
                <option value="de">German (Deutsch)</option>
                <option value="ja">Japanese (日本語)</option>
              </select>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
