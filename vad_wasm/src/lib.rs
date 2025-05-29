use wasm_bindgen::prelude::*;
use rustfft::{FftPlanner, num_complex::Complex};
use std::f32::consts::PI;

#[wasm_bindgen]
pub struct VAD {
    sample_rate: u32,
    energy_thresh: f64,
    f_thresh: f64,
    sfm_thresh: f64,
}

impl VAD {
    // Hann window implementation
    fn hann_window(size: usize) -> Vec<f32> {
        (0..size)
            .map(|i| {
                0.5 * (1.0 - (2.0 * PI * i as f32 / (size - 1) as f32).cos())
            })
            .collect()
    }
}

#[wasm_bindgen]
impl VAD {
    #[wasm_bindgen(constructor)]
    pub fn new(sample_rate: u32, energy_thresh: f64, f_thresh: f64, sfm_thresh: f64) -> VAD {
        VAD {
            sample_rate,
            energy_thresh,
            f_thresh,
            sfm_thresh,
        }
    }

    #[wasm_bindgen]
    pub fn detect_voice(&self, audio_data: &[f32]) -> Vec<u8> {
        let frame_size = (0.01 * self.sample_rate as f64) as usize;
        let num_frames = audio_data.len() / frame_size;
        
        // Prepare FFT planner
        let mut planner = FftPlanner::new();
        let fft = planner.plan_fft_forward(frame_size);
        
        // Create Hann window
        let window = Self::hann_window(frame_size);
        
        let mut energies = vec![0.0; num_frames];
        let mut dominant_freqs = vec![0.0; num_frames];
        let mut sfms = vec![0.0; num_frames];
        
        // Process each frame
        for i in 0..num_frames {
            let start = i * frame_size;
            let end = start + frame_size;
            let frame: Vec<f32> = audio_data[start..end]
                .iter()
                .zip(window.iter())
                .map(|(&x, &w)| x * w)
                .collect();
            
            // Compute FFT
            let mut spectrum: Vec<Complex<f32>> = frame
                .iter()
                .map(|&x| Complex::new(x, 0.0))
                .collect();
            fft.process(&mut spectrum);
            
            // Compute energy
            energies[i] = frame.iter().map(|&x| x * x).sum();
            
            // Find dominant frequency
            let spectrum_magnitude: Vec<f32> = spectrum[..frame_size/2]
                .iter()
                .map(|c| c.norm())
                .collect();
            let max_idx = spectrum_magnitude
                .iter()
                .enumerate()
                .max_by(|(_, a), (_, b)| a.partial_cmp(b).unwrap())
                .map(|(i, _)| i)
                .unwrap();
            dominant_freqs[i] = (max_idx as f64 * self.sample_rate as f64) / (frame_size as f64);
            
            // Compute SFM
            let geometric_mean = spectrum_magnitude
                .iter()
                .map(|&x| (x + 1e-12).ln())
                .sum::<f32>() / (frame_size/2) as f32;
            let arithmetic_mean = spectrum_magnitude.iter().sum::<f32>() / (frame_size/2) as f32;
            sfms[i] = 10.0 * (geometric_mean.exp() / (arithmetic_mean + 1e-12)).log10();
        }
        
        // Find minimum values from first 30 frames
        let min_e = energies[..30.min(num_frames)].iter().fold(f64::INFINITY, |a, &b| a.min(b as f64));
        let min_f = dominant_freqs[..30.min(num_frames)].iter().fold(f64::INFINITY, |a, &b| a.min(b));
        let min_sfm = sfms[..30.min(num_frames)].iter().fold(f64::INFINITY, |a, &b| a.min(b as f64));
        
        let mut thresh_e = self.energy_thresh * (min_e + 1e-12).ln();
        let thresh_f = self.f_thresh;
        let thresh_sfm = self.sfm_thresh;
        
        let mut silence_count = 0;
        let mut min_e_dynamic = min_e;
        let mut decisions = Vec::with_capacity(num_frames);
        
        // Make decisions for each frame
        for i in 0..num_frames {
            let mut counter = 0;
            
            if energies[i] as f64 - min_e_dynamic >= thresh_e {
                counter += 1;
            }
            if dominant_freqs[i] - min_f >= thresh_f {
                counter += 1;
            }
            if sfms[i] as f64 - min_sfm >= thresh_sfm {
                counter += 1;
            }
            
            if counter > 1 {
                decisions.push(true);
            } else {
                decisions.push(false);
                silence_count += 1;
                min_e_dynamic = (silence_count as f64 * min_e_dynamic + energies[i] as f64) / (silence_count + 1) as f64;
                thresh_e = self.energy_thresh * (min_e_dynamic + 1e-12).ln();
            }
        }
        
        // Smooth decisions
        decisions = self.smooth_decisions(&decisions, 10, false);
        decisions = self.smooth_decisions(&decisions, 5, true);
        
        // Convert bool decisions to u8 (0 or 1)
        decisions.into_iter().map(|b| if b { 1 } else { 0 }).collect()
    }
    
    fn smooth_decisions(&self, decisions: &[bool], min_len: usize, label: bool) -> Vec<bool> {
        let mut result = decisions.to_vec();
        let mut start = 0;
        
        while start < result.len() {
            if result[start] == label {
                let mut end = start;
                while end < result.len() && result[end] == label {
                    end += 1;
                }
                if end - start < min_len {
                    for k in start..end {
                        result[k] = !label;
                    }
                }
                start = end;
            } else {
                start += 1;
            }
        }
        
        result
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_vad() {
        let vad = VAD::new(16000, 0.30, 316.76, 0.60);
        let test_audio = vec![0.0; 16000]; // 1 second of silence
        let decisions = vad.detect_voice(&test_audio);
        assert_eq!(decisions.len(), 100); // 100 frames for 1 second at 10ms frame size
    }

    #[test]
    fn test_hann_window() {
        let window = VAD::hann_window(8);
        assert_eq!(window.len(), 8);
        // Check window properties
        assert!((window[0] - 0.0).abs() < 1e-6);
        assert!((window[window.len()/2] - 1.0).abs() < 1e-6);
        assert!((window[window.len()-1] - 0.0).abs() < 1e-6);
    }
}
