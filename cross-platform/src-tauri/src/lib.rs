use serde::{Deserialize, Serialize};
use std::sync::atomic::AtomicBool;
use std::sync::RwLock;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SubtitleCue {
    pub start: f64,
    pub end: f64,
    pub text: String,
}

pub struct PlayerState {
    pub is_playing: AtomicBool,
    pub playback_speed: RwLock<f64>,
    pub cues: RwLock<Vec<SubtitleCue>>,
}

impl Default for PlayerState {
    fn default() -> Self {
        Self {
            is_playing: AtomicBool::new(false),
            playback_speed: RwLock::new(1.0),
            cues: RwLock::new(Vec::new()),
        }
    }
}

mod commands {
    use super::{parse_srt_timestamp, SubtitleCue};

    #[tauri::command]
    pub fn parse_srt_subtitles(raw_srt: String) -> Vec<SubtitleCue> {
        let mut cues = Vec::new();
        let blocks: Vec<&str> = raw_srt.split("\n\n").collect();

        for block in blocks {
            let lines: Vec<&str> = block.lines().map(|l| l.trim()).filter(|l| !l.is_empty()).collect();
            if lines.len() >= 2 {
                let time_line = if lines[0].parse::<usize>().is_ok() && lines.len() >= 3 {
                    lines[1]
                } else {
                    lines[0]
                };

                let text_lines = if lines[0].parse::<usize>().is_ok() && lines.len() >= 3 {
                    &lines[2..]
                } else {
                    &lines[1..]
                };

                if let Some((start_str, end_str)) = time_line.split_once("-->") {
                    let start = parse_srt_timestamp(start_str.trim());
                    let end = parse_srt_timestamp(end_str.trim());
                    let text = text_lines.join("\n");
                    cues.push(SubtitleCue { start, end, text });
                }
            }
        }
        cues
    }

    #[tauri::command]
    pub fn format_duration(seconds: f64) -> String {
        let total_secs = seconds.floor() as u64;
        let hrs = total_secs / 3600;
        let mins = (total_secs % 3600) / 60;
        let secs = total_secs % 60;
        if hrs > 0 {
            format!("{:02}:{:02}:{:02}", hrs, mins, secs)
        } else {
            format!("{:02}:{:02}", mins, secs)
        }
    }
}

fn parse_srt_timestamp(ts: &str) -> f64 {
    let parts: Vec<&str> = ts.split(':').collect();
    if parts.len() == 3 {
        let hours: f64 = parts[0].parse().unwrap_or(0.0);
        let mins: f64 = parts[1].parse().unwrap_or(0.0);
        let sec_parts: Vec<&str> = parts[2].split(|c| c == ',' || c == '.').collect();
        let secs: f64 = sec_parts.first().and_then(|s| s.parse().ok()).unwrap_or(0.0);
        let millis: f64 = sec_parts.get(1).and_then(|s| s.parse().ok()).unwrap_or(0.0);
        hours * 3600.0 + mins * 60.0 + secs + (millis / 1000.0)
    } else {
        0.0
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .manage(PlayerState::default())
        .invoke_handler(tauri::generate_handler![
            commands::parse_srt_subtitles,
            commands::format_duration
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
