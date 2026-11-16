package main

import (
	"bytes"
	"encoding/binary"
	"os"
	"path/filepath"
	"testing"
)

func TestRejectInvalidMemoryWithoutReplacingOutput(t *testing.T) {
	for _, tc := range []struct {
		name, segment string
		memory        []byte
	}{
		{"segment", "0x10000", make([]byte, 0x5000)},
		{"truncated", "0", make([]byte, 0x4457)},
		{"start", "0", func() []byte { b := make([]byte, 0x5000); binary.LittleEndian.PutUint16(b[0x1410:], 64); return b }()},
		{"fixture count", "0", func() []byte { b := make([]byte, 0x5000); binary.LittleEndian.PutUint16(b[0x493c:], 101); return b }()},
	} {
		t.Run(tc.name, func(t *testing.T) {
			dir := t.TempDir()
			in, out := filepath.Join(dir, "memory"), filepath.Join(dir, "map.tsv")
			if err := os.WriteFile(in, tc.memory, 0600); err != nil {
				t.Fatal(err)
			}
			before := []byte("existing export\n")
			if err := os.WriteFile(out, before, 0600); err != nil {
				t.Fatal(err)
			}
			if err := export(tc.segment, in, out, filepath.Join(dir, "fixtures.tsv")); err == nil {
				t.Fatal("accepted invalid memory")
			}
			after, err := os.ReadFile(out)
			if err != nil {
				t.Fatal(err)
			}
			if !bytes.Equal(before, after) {
				t.Fatal("invalid memory replaced existing export")
			}
		})
	}
}
