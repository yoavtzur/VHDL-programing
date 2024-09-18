# FPGA Processor Project in VHDL

## Overview

This project implements a processor using VHDL and targets an FPGA platform. The design includes essential components such as an Arithmetic Logic Unit (ALU), a division unit, interrupt controllers, a shifter, memory units, and input/output modules. The processor follows a MIPS-like architecture, handling basic and advanced computations while managing interrupts and GPIO communication.

## Files Overview

- **EXECUTE.vhd**: Handles the execution of instructions, including ALU operations and branching logic.
- **unsigned_division.vhd**: Implements an unsigned division unit for the processor.
- **Shifter.vhd**: Implements shifting operations for bit manipulation.
- **MIPS.vhd**: Top-level entity describing the MIPS-like processor.
- **MCU.vhd**: Microcontroller unit for managing the processor's overall operation.
- **InterruptController.vhd**: Manages interrupts and ensures smooth interrupt handling.
- **IFETCH.vhd**: Fetches instructions from memory into the processor pipeline.
- **IDECODE.vhd**: Decodes fetched instructions, preparing them for execution.
- **hexDecoder.vhd**: Converts binary data into hexadecimal format.
- **GPIO.vhd**: Manages communication with General Purpose Input/Output (GPIO) devices.
- **DMEMORY.vhd**: Data memory module for storing and retrieving processed data.
- **Divider.vhd**: Implements a division unit within the processor.
- **CONTROL.vhd**: Control unit that manages the signals and controls across the processor.
- **BidirPin.vhd**: Handles bidirectional communication pins.
- **BasicTimer.vhd**: A basic timer used for timing operations within the processor.
- **PLL.vhd**: Phase-Locked Loop (PLL) module for clock signal synchronization.
- **SDC1.sdc**: Synopsys Design Constraints file for timing and design constraints.
- **PLL_0002.qip**: Quartus IP File for PLL configuration.
- **PLL_0002.v**: Verilog file for the PLL component.

## Features

- MIPS-like architecture with instruction fetch, decode, and execute stages.
- Support for arithmetic operations, including division and bit manipulation.
- Interrupt controller for handling external/internal interrupts.
- GPIO interface for communication with external devices.
- Data memory module for storing results.
- Phase-Locked Loop (PLL) for stable clock synchronization.
- Basic Timer module for time-dependent operations.

## Requirements

- **FPGA Platform**: This project is designed for synthesis and implementation on FPGA platforms.
- **VHDL Compiler**: You will need a VHDL compiler (e.g., ModelSim, Xilinx Vivado) for simulation and testing.





