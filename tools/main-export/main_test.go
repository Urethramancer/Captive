package main

import (
	"encoding/binary"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestMainDescriptorBoundsAndChecksum(t *testing.T) {
	validHeader := func() []byte {
		b := make([]byte, 95872)
		w := func(p int, n uint32) { binary.BigEndian.PutUint32(b[p:], n) }
		w(0, 0x3f3)
		w(8, 1)
		w(20, 0x5d97)
		w(24, 0x3e9)
		w(28, 0x5d97)
		w(len(b)-4, 0x3f2)
		return b
	}
	for _, tc := range []struct {
		name string
		data []byte
		want string
	}{
		{"header", make([]byte, 35), "truncated"},
		{"size", func() []byte { b := validHeader(); binary.BigEndian.PutUint32(b[28:], 0xffffffff); return b }(), "size"},
		{"end", func() []byte { b := validHeader(); b[len(b)-1] = 0; return b }(), "HUNK_END"},
		{"checksum", validHeader(), "checksum"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, err := validateMain(tc.data)
			if err == nil || !strings.Contains(err.Error(), tc.want) {
				t.Fatalf("got %v, want %s rejection", err, tc.want)
			}
		})
	}
	if _, err := readDescriptors(make([]byte, 0x4102)); err == nil {
		t.Fatal("accepted truncated descriptor array")
	}
}

func TestFirstBaseStockGates(t *testing.T) {
	for shop := 1; shop <= 6; shop++ {
		for group := 0; group <= 9; group++ {
			want := group == 0 || (group == 2 && shop == 2)
			if got := available(group, shop, 0); got != want {
				t.Fatalf("group %d shop %d: got %v, want %v", group, shop, got, want)
			}
		}
	}
	if !available(3, 3, 1) {
		t.Fatal("second-base sword group should become available")
	}
}

func TestOriginalQualityMaskVectors(t *testing.T) {
	for _, tc := range []struct {
		index, data, shop int
		want              uint8
	}{{12, 10, 2, 245}, {13, 20, 2, 163}, {9, 24, 1, 217}, {9, 24, 2, 163}} {
		if got := qualityMask(tc.index, tc.data, tc.shop, 0, 0); got != tc.want {
			t.Fatalf("item %d shop %d mask %d, want %d", tc.index, tc.shop, got, tc.want)
		}
	}
}

func TestRejectDuplicateOrOutOfBoundsShops(t *testing.T) {
	for _, text := range []string{"number\tx\ty\n1\t64\t0\n", "number\tx\ty\n1\t27\t17\n1\t24\t2\n", "number\tx\ty\n"} {
		p := filepath.Join(t.TempDir(), "shops.tsv")
		if err := os.WriteFile(p, []byte(text), 0600); err != nil {
			t.Fatal(err)
		}
		if _, err := readShops(p); err == nil {
			t.Fatalf("accepted invalid shops %q", text)
		}
	}
}
