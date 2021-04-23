
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name ALINX_RTC_UART_7SEGMENT -dir "D:/Xilinx_FPGA/ALINX_RTC_UART_7SEGMENT/planAhead_run_1" -part xc6slx9ftg256-2
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "UCF_Constraints.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {ipcore_dir/DCM_CLOCK.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {UART.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {seven_segment.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {RTC_driver.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {Main.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set_property top Main $srcset
add_files [list {UCF_Constraints.ucf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6slx9ftg256-2
