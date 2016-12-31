VFLAGS_rx_buffer_tb := -DTARGET_s3  # set oddball configuration in rx_buffer.v

bandpass3.dat: bandpass3_tb cset3.m
	$(VVP) $< `$(OCTAVE) -q cset3.m` > $@

bandpass3_check: bpp3.m bandpass3.dat
	$(OCTAVE) -q $(notdir $<)

half_filt.dat: half_filt_tb
	$(VVP) $< > $@

half_filt_check: half_filt.m half_filt.dat
	$(OCTAVE) -q half_filt.m

# scattershot approach
# limited to den>=12
mon_12_check: mon_12_tb ../build/testcode.awk
	$(VVP) $< +amp=20000 +den=16  +phs=3.14 | $(AWK) -f $(filter %.awk, $^)
	$(VVP) $< +amp=32763 +den=128 +phs=-0.2 | $(AWK) -f $(filter %.awk, $^)
	$(VVP) $< +amp=99999 +den=28  +phs=1.57 | $(AWK) -f $(filter %.awk, $^)
	$(VVP) $< +amp=200   +den=12  +phs=0.70 | $(AWK) -f $(filter %.awk, $^)
