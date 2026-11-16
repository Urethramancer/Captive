// Captive's original-derived maps are local inspection data, not redistributable assets.
package main

import (
	"bytes"
	"encoding/binary"
	"flag"
	"fmt"
	"os"
	"strconv"
)

func main() {
	segment := flag.String("ds", "", "DOS data segment, for example 0x275b; discover for each process")
	fixtures := flag.String("fixtures", "", "also export the wall-fixture registry to this TSV")
	traps := flag.String("traps", "", "also export cupboard-to-wall trap links to this TSV")
	shops := flag.String("shops", "", "also export numbered shop coordinates to this TSV")
	info := flag.String("info", "", "also export seed, entrance and floor sections to this TSV")
	flag.Parse()
	if flag.NArg() != 2 || *segment == "" {
		fmt.Fprintln(os.Stderr, "usage: go run tools/mapgen-export/main.go -ds SEGMENT MEMORY OUTPUT.tsv")
		os.Exit(2)
	}
	if err := export(*segment, flag.Arg(0), flag.Arg(1), *fixtures, *traps, *shops, *info); err != nil {
		fmt.Fprintln(os.Stderr, "mapgen-export:", err)
		os.Exit(1)
	}
}

func export(segment, input, output, fixtures, traps, shops string, info ...string) error {
	s, err := strconv.ParseUint(segment, 0, 16)
	if err != nil {
		return fmt.Errorf("invalid data segment: %w", err)
	}
	memory, err := os.ReadFile(input)
	if err != nil {
		return err
	}
	base := int(s) * 16
	if len(memory) < base+0x4458 {
		return fmt.Errorf("memory is truncated: need at least %d bytes for DS %s", base+0x4458, segment)
	}
	word := func(offset int) uint16 {
		return binary.LittleEndian.Uint16(memory[base+offset:])
	}
	var fixtureTable bytes.Buffer
	var trapTable bytes.Buffer
	var shopTable bytes.Buffer
	if shops != "" {
		if len(memory) < base+0x4970 {
			return fmt.Errorf("memory is truncated before the shop registry pointer")
		}
		start := int(word(0x496e))
		if len(memory) < base+start+18 {
			return fmt.Errorf("memory is truncated in the shop registry")
		}
		shopTable.WriteString("number\tx\ty\n")
		for i := 0; i < 9; i++ {
			record := memory[base+start+2*i : base+start+2*i+2]
			if record[0] == 255 && record[1] == 255 {
				break
			}
			if record[0] >= 64 || record[1] >= 32 {
				return fmt.Errorf("invalid shop %d", i+1)
			}
			fmt.Fprintf(&shopTable, "%d\t%d\t%d\n", i+1, record[0], record[1])
		}
	}
	if traps != "" {
		if len(memory) < base+0x4982 {
			return fmt.Errorf("memory is truncated before the trap registry pointer")
		}
		start, count := int(word(0x4980)), int(word(0x47c2))
		if count > 32 || len(memory) < base+start+4*count {
			return fmt.Errorf("invalid cupboard-trap registry")
		}
		trapTable.WriteString("cupboardX\tcupboardY\twallX\twallY\n")
		for i := 0; i < count; i++ {
			record := memory[base+start+4*i : base+start+4*i+4]
			if record[0] >= 64 || record[1] >= 32 || record[2] >= 64 || record[3] >= 32 {
				return fmt.Errorf("invalid cupboard trap %d", i)
			}
			fmt.Fprintf(&trapTable, "%d\t%d\t%d\t%d\n", record[0], record[1], record[2], record[3])
		}
	}
	if fixtures != "" {
		if len(memory) < base+0x4974 {
			return fmt.Errorf("memory is truncated before the registry pointers")
		}
		start, count := int(word(0x4972)), int(word(0x493c))
		if count > 100 || len(memory) < base+start+4*count {
			return fmt.Errorf("invalid wall-fixture registry")
		}
		fixtureTable.WriteString("x\ty\ttype\textra\n")
		for i := 0; i < count; i++ {
			record := memory[base+start+4*i : base+start+4*i+4]
			if record[0] >= 64 || record[1] >= 32 || record[2] > 5 {
				return fmt.Errorf("invalid wall fixture %d: check DS and generation state", i)
			}
			fmt.Fprintf(&fixtureTable, "%d\t%d\t%d\t%d\n", record[0], record[1], record[2], record[3])
		}
	}
	x, y := word(0x1410), word(0x1412)
	if x >= 64 || y >= 32 {
		return fmt.Errorf("invalid start (%d,%d): check DS and generation state", x, y)
	}
	var metadata bytes.Buffer
	if len(info) > 0 && info[0] != "" {
		if len(memory) < base+0x446a {
			return fmt.Errorf("memory is truncated before the map seed")
		}
		metadata.WriteString("seed\tstartX\tstartY\tfacing\tfloors\n")
		fmt.Fprintf(&metadata, "%d\t%d\t%d\t2\t", word(0x4468), x, y)
		for i, level := range memory[base+0x13f0 : base+0x1400] {
			if level < 1 || level > 6 {
				return fmt.Errorf("invalid floor section %d", i)
			}
			if i > 0 {
				metadata.WriteByte(',')
			}
			fmt.Fprintf(&metadata, "%d", level)
		}
		metadata.WriteByte('\n')
	}
	var table bytes.Buffer
	table.WriteString("x\ty\tterrain\tobject\tdetail\n")
	for row := 0; row < 32; row++ {
		for column := 0; column < 64; column++ {
			i := 2 * (row*64 + column)
			fmt.Fprintf(&table, "%d\t%d\t%04x\t%04x\t%04x\n", column, row, word(0x1428+i), word(0x2438+i), word(0x3448+i))
		}
	}
	// Validate and construct everything before touching an existing output.
	if err := writeAtomic(output, table.Bytes()); err != nil {
		return err
	}
	if fixtures != "" {
		if err := writeAtomic(fixtures, fixtureTable.Bytes()); err != nil {
			return err
		}
	}
	if traps != "" {
		if err := writeAtomic(traps, trapTable.Bytes()); err != nil {
			return err
		}
	}
	if shops != "" {
		if err := writeAtomic(shops, shopTable.Bytes()); err != nil {
			return err
		}
	}
	if metadata.Len() > 0 {
		if err := writeAtomic(info[0], metadata.Bytes()); err != nil {
			return err
		}
	}
	fmt.Printf("Exported 64×32 cells; start (%d,%d).\n", x, y)
	return nil
}

func writeAtomic(output string, data []byte) error {
	file, err := os.CreateTemp("", "captive-mapgen-*.tsv")
	if err != nil {
		return err
	}
	name := file.Name()
	defer os.Remove(name)
	if _, err = file.Write(data); err != nil {
		file.Close()
		return err
	}
	if err = file.Close(); err != nil {
		return err
	}
	if err = os.Rename(name, output); err != nil {
		return err
	}
	return nil
}
