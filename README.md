# VGA-lines
Working code to try to implement Bresingham Line Algorithm in VHDL for an Altera DE2 FPGA

Authored by Tea Jay Macalanda-Ung and Keltie Murdoch
October 20, 2015

Status: Testing
Currently the top-level design entity requires refactoring
There is a lot of commented code which needs to be removed
There is a wrap-around bug in the line algorithm process
  -Currently the slope function is not being implemented correctly
  -Instead of incrementing the output y pixel according to the slope, it is incrementing once per clock cycle
  -This results in a slope too sharp and the y pixels then wrap around
  -The wrap around keeps the datapath from ever triggering a "done" flag to move the state machine to next state
The colour function appears to be working
The value of i (applied in the project) appears to be incrementing correctly
The x and y output values are being updated at the correct time

Next Step: 
We suspect implementing the algorithm using integers and pos/neg flags was incorrect.
We plan to test a separate version using signed arithmetic instead.
