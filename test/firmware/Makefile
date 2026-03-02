TOOLCHAIN_PREFIX = ./riscv32-unknown-elf.gcc-12.1.0/bin/riscv32-unknown-elf-

firmware.hex: firmware.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

firmware.elf: firmware_sections.lds start.s firmware.c
	$(TOOLCHAIN_PREFIX)gcc -DHX8KDEMO -mabi=ilp32 -march=rv32imc \
		-Wl,--build-id=none,-Bstatic,-T,firmware_sections.lds,--strip-debug \
		-ffreestanding -nostdlib -o $@ start.s firmware.c

firmware_sections.lds: sections.lds
	$(TOOLCHAIN_PREFIX)cpp -P -DHX8KDEMO -o $@ $<

clean:
	rm -f firmware.elf firmware.hex firmware_sections.lds

.PHONY: clean
