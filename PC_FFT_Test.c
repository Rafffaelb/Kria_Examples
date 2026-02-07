/*
 * Test C Application for FFT Logic
 * ==========================================
 * This C file can be compiled on your local PC (not MicroBlaze) to verify
 * the FFT logic functionality before running it on hardware.
 *
 * To compile: gcc PC_FFT_Test.c -o fft_test -lm
 * To run: ./fft_test
 */

#include <stdio.h>
#include <math.h>
#include <stdlib.h>

#define SAMPLES_COUNT 128
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Structure format matching the embedded code
typedef struct {
    float real;
    float imag;
} complex_t;

complex_t signal[SAMPLES_COUNT];

// --- FFT Implementation (Copy from main.c) ---
void fft(complex_t *X, int N) {
    if (N <= 1) return;

    complex_t even[N/2];
    complex_t odd[N/2];

    for (int i = 0; i < N/2; i++) {
        even[i] = X[2*i];
        odd[i] = X[2*i + 1];
    }

    fft(even, N/2);
    fft(odd, N/2);

    for (int k = 0; k < N/2; k++) {
        float r = even[k].real;
        float i = even[k].imag;
        
        float angle = -2 * M_PI * k / N;
        float wr = cos(angle);
        float wi = sin(angle);
        
        float tr = wr * odd[k].real - wi * odd[k].imag;
        float ti = wr * odd[k].imag + wi * odd[k].real;
        
        X[k].real = r + tr;
        X[k].imag = i + ti;
        
        X[k + N/2].real = r - tr;
        X[k + N/2].imag = i - ti;
    }
}

// --- Main Test Bench ---
int main() {
    printf("Verify FFT Logic (PC-based Test)\n");
    printf("--------------------------------\n");

    // 1. Generate Input Signal: 10Hz sine wave + 30Hz sine wave
    // Sampling rate assumed arbitrary, e.g., 128Hz for simplicity (N=128)
    // So 10Hz = index 10, 30Hz = index 30.
    
    printf("Generating Signal: 10Hz (Amp 1.0) + 30Hz (Amp 0.5)...\n");
    for (int i = 0; i < SAMPLES_COUNT; i++) {
        float t = (float)i / SAMPLES_COUNT; // Time 0 to 1 sec
        signal[i].real = 1.0f * sin(2 * M_PI * 10 * t) + 0.5f * sin(2 * M_PI * 30 * t);
        signal[i].imag = 0.0f;
    }

    // 2. Run FFT
    fft(signal, SAMPLES_COUNT);

    // 3. Print Output
    printf("FFT Results (Magnitudes > 1.0):\n");
    printf("Index\tFreq(Norm)\tMagnitude\n");
    
    int peaks_found = 0;
    for (int i = 0; i < SAMPLES_COUNT / 2; i++) { // Only first half is useful for real input
        float mag = sqrt(signal[i].real * signal[i].real + signal[i].imag * signal[i].imag);
        
        // Simple threshold to show peaks
        if (mag > 5.0f) { 
            printf("%d\t%.2f\t\t%.2f\n", i, (float)i, mag);
            peaks_found++;
        }
    }
    
    if(peaks_found >= 2) {
        printf("\nSUCCESS: Peaks detected (likely at index 10 and 30)\n");
    } else {
        printf("\nFAILURE: Peaks not clearly detected.\n");
    }

    return 0;
}
