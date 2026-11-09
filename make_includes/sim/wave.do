# Log every signal in the design, recursively, so the WLF has everything
log -r /*

# Add everything to the waveform window (only matters with GUI=1)
add wave -r /*

# Optional niceties
configure wave -signalnamewidth 1
wave zoom full