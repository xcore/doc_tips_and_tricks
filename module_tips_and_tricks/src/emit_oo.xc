void emit_bits_oo(struct pers &state,int code,int length) {
    state.length += length;
    if (state.length > 32) {
        int t;
        state.length -= 32;
        t = state.current << (length - state.length);
        t |= code >> state.length;
        state.codes[state.ncodes] = t;
        state.ncodes++;
        state.current = code;
    } else {
        state.current <<= length;
        state.current |= code;
    }
}

void encode_oo(int block[64]) {
    int temp, i, k, temp2, nbits;
    int r = 0;
    struct pers state; state.ncodes = state.length = 0;
    for (k = 0; k < 64; k++) {
        if ((temp = block[k]) == 0) {
            r++;
        } else {
            while (r > 15) {
                emit_bits_oo(state,ehufco[0xF0],ehufsi[0xF0]);
                r -= 16;
            }
            temp2 = temp;
            if (temp < 0) {
                temp = -temp;
                temp2--;
            }
            nbits = 32-clz(temp);
            i = (r << 4) + nbits;
            emit_bits_oo(state, ehufco[i], ehufsi[i]);
            emit_bits_oo(state, (unsigned int) temp2, nbits);
            r = 0;
        }
    }
}
