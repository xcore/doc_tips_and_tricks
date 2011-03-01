void emit_bits_c(streaming chanend inp) {
  int code, length, state_current;
  int state_length = 0, state_ncodes = 0, state_codes[512];
  while(1) {
    inp :> code;   inp :> length;
    state_length += length;
    if (state_length > 32) {
        int t;
        state_length -= 32;
        t = state_current << (length - state_length);
        t |= code >> state_length;
        state_codes[state_ncodes] = t;
        state_ncodes++;
        state_current = code;
    } else {
        state_current <<= length;
        state_current |= code;
    }
  }
}

void encode_c(streaming chanend outp, int block[64]) {
    int temp, i, k, temp2, nbits;
    int r = 0;

    for (k = 0; k < 64; k++) {
        if ((temp = block[k]) == 0) {
            r++;
        } else {
            while (r > 15) {
                outp <: ehufco[0xF0]; outp <: ehufsi[0xF0];
                r -= 16;
            }
            temp2 = temp;
            if (temp < 0) {
                temp = -temp;
                temp2--;
            }
            nbits = 32-clz(temp);
            i = (r << 4) + nbits;
            outp <: ehufco[i]; outp <: ehufsi[i];
            outp <: (unsigned int) temp2; outp <: nbits;
            r = 0;
        }
    }
}
