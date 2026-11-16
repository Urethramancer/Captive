// Extract inspection data from the user's local original game. Outputs are not redistributable.
package main

import (
	"bufio"
	"bytes"
	"crypto/sha256"
	"encoding/binary"
	"fmt"
	"math/bits"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

const originalHash = "8545561236cf6e0f773cd1ae886be13cc9bedf51c53595c28c3b2e259c4dabbc"

type shop struct{ number, x, y int }
type descriptor struct {
	index, itemData, price, increment, group, flags int
	name, kind                                      string
}

func main() {
	if len(os.Args) != 4 {
		fmt.Fprintln(os.Stderr, "usage: go run tools/main-export/main.go FEDERATION BASE0-SHOPS.tsv OUTPUT.tsv")
		os.Exit(2)
	}
	if err := run(os.Args[1], os.Args[2], os.Args[3]); err != nil {
		fmt.Fprintln(os.Stderr, "main-export:", err)
		os.Exit(1)
	}
}

func run(input, shopPath, output string) error {
	data, err := os.ReadFile(input)
	if err != nil {
		return err
	}
	code, err := validateMain(data)
	if err != nil {
		return err
	}
	shops, err := readShops(shopPath)
	if err != nil {
		return err
	}
	descriptors, err := readDescriptors(code)
	if err != nil {
		return err
	}
	var table bytes.Buffer
	table.WriteString("shop\tx\ty\titem\tkind\tcategory\tquality\tprice\titemData\tflags\tname\n")
	rows := 0
	for _, s := range shops {
		for _, d := range descriptors {
			if !available(d.group, s.number, 0) || d.price == 0 {
				continue
			}
			category := -1
			if d.kind == "weapon" {
				category = 0
			}
			for q := 0; q < 8; q++ {
				if d.flags&1 == 0 {
					if q != 0 {
						continue
					}
				} else if qualityMask(d.index, d.itemData, s.number, 0, 0)&(1<<(7-q)) == 0 {
					continue
				}
				price := d.price
				if d.flags&1 != 0 {
					price += d.increment * q
				}
				fmt.Fprintf(&table, "%d\t%d\t%d\t%d\t%s\t%d\t%d\t%d\t%d\t%d\t%s\n", s.number, s.x, s.y, d.index+19, d.kind, category, q, price, d.itemData, d.flags, d.name)
				rows++
			}
		}
	}
	file, err := os.CreateTemp(filepath.Dir(output), ".captive-stock-*.tsv")
	if err != nil {
		return err
	}
	defer os.Remove(file.Name())
	if _, err = file.Write(table.Bytes()); err != nil {
		file.Close()
		return err
	}
	if err = file.Close(); err != nil {
		return err
	}
	if err = os.Rename(file.Name(), output); err != nil {
		return err
	}
	fmt.Printf("Exported %d original stock offers across %d shops.\n", rows, len(shops))
	return nil
}

func validateMain(data []byte) ([]byte, error) {
	if len(data) < 36 {
		return nil, fmt.Errorf("truncated Amiga hunk header")
	}
	w := func(offset int) uint32 { return binary.BigEndian.Uint32(data[offset:]) }
	if w(0) != 0x3f3 || w(4) != 0 || w(8) != 1 || w(12) != 0 || w(16) != 0 || w(24) != 0x3e9 {
		return nil, fmt.Errorf("unsupported Amiga hunk descriptor")
	}
	size := uint64(w(28)) * 4
	if size != uint64(w(20))*4 || size+36 != uint64(len(data)) {
		return nil, fmt.Errorf("invalid Amiga code size")
	}
	if w(len(data)-4) != 0x3f2 {
		return nil, fmt.Errorf("missing Amiga HUNK_END")
	}
	if size < 0x4102+95*8 {
		return nil, fmt.Errorf("code is truncated before the shop table")
	}
	if fmt.Sprintf("%x", sha256.Sum256(data)) != originalHash {
		return nil, fmt.Errorf("unsupported federation checksum; verify this revision before using fixed table offsets")
	}
	return data[32 : 32+size], nil
}

func readDescriptors(code []byte) ([]descriptor, error) {
	if len(code) < 0x4102+95*8 {
		return nil, fmt.Errorf("truncated shop descriptors")
	}
	names := make([]string, 84)
	p := 0x3d0e
	for i := range names {
		start := p
		for p < len(code) && code[p] != 0 {
			p++
		}
		if p+1 >= len(code) {
			return nil, fmt.Errorf("truncated item name %d", i)
		}
		for _, c := range code[start:p] {
			if c >= 32 && c <= 90 {
				names[i] += string(c)
			}
		}
		names[i] = strings.TrimSpace(names[i])
		p += 2
	}
	var out []descriptor
	for i := 0; i < 95; i++ {
		p := 0x4102 + 8*i
		w := func(n int) int { return int(binary.BigEndian.Uint16(code[p+n:])) }
		d := descriptor{index: i, itemData: w(0), price: w(2), increment: w(4), group: int(code[p+6]), flags: int(code[p+7])}
		if d.price == 0 {
			continue
		}
		if i >= len(names) || names[i] == "" {
			return nil, fmt.Errorf("priced item %d lacks a name", i)
		}
		d.name = names[i]
		switch {
		case i < 6:
			d.kind = "armour"
		case i == 7:
			d.kind = "battery"
		case i == 8:
			d.kind = "explosives"
		case i == 9:
			d.kind = "device"
		case i == 10:
			d.kind = "optic"
		case i == 11:
			d.kind = "camera"
		case i >= 12 && i <= 34:
			d.kind = "weapon"
		case i >= 58 && i <= 71:
			d.kind = "ammo"
		case i == 75:
			d.kind = "mine"
		case i == 77:
			d.kind = "ball"
		default:
			return nil, fmt.Errorf("unclassified priced item %d", i)
		}
		out = append(out, d)
	}
	return out, nil
}

func available(group, number, seed int) bool {
	if group == 0 {
		return true
	}
	base := min(seed, 100) + 1
	if group == 1 {
		return base/2 > number-1
	}
	if group == number {
		return base > group-2
	}
	if group == number+1 || group == number+2 {
		return base > group+1
	}
	return false
}

func qualityMask(index, itemData, number, material, seed int) uint8 {
	if index <= 5 && material == 0 {
		return 128
	}
	n := bits.RotateLeft16(uint16(material), 4) + uint16(index+itemData+number)
	n = bits.RotateLeft16(n, 4) + uint16(seed)
	n = n*1509 + 41
	n = bits.RotateLeft16(n, -3) ^ 0x800
	mask := uint8(n)
	if mask == 0 {
		return 128
	}
	return mask
}

func readShops(path string) ([]shop, error) {
	file, err := os.Open(path)
	if err != nil {
		return nil, err
	}
	defer file.Close()
	scan := bufio.NewScanner(file)
	if !scan.Scan() || scan.Text() != "number\tx\ty" {
		return nil, fmt.Errorf("invalid numbered-shop header")
	}
	var out []shop
	seen := map[int]bool{}
	for scan.Scan() {
		f := strings.Split(scan.Text(), "\t")
		if len(f) != 3 {
			return nil, fmt.Errorf("invalid shop record")
		}
		v := [3]int{}
		for i := range v {
			n, e := strconv.Atoi(f[i])
			if e != nil {
				return nil, e
			}
			v[i] = n
		}
		s := shop{v[0], v[1], v[2]}
		if s.number < 1 || s.number > 9 || s.x < 0 || s.x >= 64 || s.y < 0 || s.y >= 32 || seen[s.number] {
			return nil, fmt.Errorf("invalid or duplicate shop %d", s.number)
		}
		seen[s.number] = true
		out = append(out, s)
	}
	if err = scan.Err(); err != nil {
		return nil, err
	}
	if len(out) != 6 {
		return nil, fmt.Errorf("first base requires six numbered shops, got %d", len(out))
	}
	return out, nil
}
