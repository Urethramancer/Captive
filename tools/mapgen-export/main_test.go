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
			if err := export(tc.segment, in, out, filepath.Join(dir, "fixtures.tsv"), "", ""); err == nil {
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

func TestExportRegistries(t *testing.T) {
	b := make([]byte, 0x5000)
	word := func(offset int, v uint16) { binary.LittleEndian.PutUint16(b[offset:], v) }
	word(0x1410, 30)
	word(0x1412, 1)
	word(0x4468, 1)
	for i := 0; i < 16; i++ {
		b[0x13f0+i] = 1
	}
	word(0x493c, 1)
	word(0x4972, 0x4800)
	copy(b[0x4800:], []byte{29, 1, 0, 0})
	word(0x47c2, 1)
	word(0x4980, 0x4810)
	copy(b[0x4810:], []byte{26, 1, 27, 0})
	word(0x496e, 0x4818)
	copy(b[0x4818:], []byte{27, 17, 24, 2, 255, 255})
	dir := t.TempDir()
	in := filepath.Join(dir, "memory")
	if err := os.WriteFile(in, b, 0600); err != nil {
		t.Fatal(err)
	}
	paths := []string{filepath.Join(dir, "map"), filepath.Join(dir, "fixtures"), filepath.Join(dir, "traps"), filepath.Join(dir, "shops")}
	info := filepath.Join(dir, "info")
	if err := export("0", in, paths[0], paths[1], paths[2], paths[3], info); err != nil {
		t.Fatal(err)
	}
	metadata, err := os.ReadFile(info)
	if err != nil || string(metadata) != "seed\tstartX\tstartY\tfacing\tfloors\n1\t30\t1\t2\t1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1\n" {
		t.Fatalf("incorrect map metadata: %q, %v", metadata, err)
	}
	for i, want := range []string{"x\ty\ttype\textra\n29\t1\t0\t0\n", "cupboardX\tcupboardY\twallX\twallY\n26\t1\t27\t0\n", "number\tx\ty\n1\t27\t17\n2\t24\t2\n"} {
		got, err := os.ReadFile(paths[i+1])
		if err != nil {
			t.Fatal(err)
		}
		if string(got) != want {
			t.Fatalf("registry %d: %q", i, got)
		}
	}
	got, err := os.ReadFile(paths[0])
	if err != nil {
		t.Fatal(err)
	}
	if lines := bytes.Count(got, []byte{'\n'}); lines != 2049 {
		t.Fatalf("map has %d lines", lines)
	}
}
