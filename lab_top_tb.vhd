library ieee;
use ieee.std_logic_1164.all;

---------------------------------------------------------------------
--
-- This is a test bench used to test your state machine in Modelsim.
-- This is not part of the state machine design, it is only used to
-- drive inputs and outputs during testing in Modelsim.  You would 
-- not try to compile this using Quartus II.
--
-- This is the most bare-bones testbench I could think of.  You can
-- enhance this significantly to increase the quality of your tests.
--
---------------------------------------------------------------------


-- A test bench has no inputs or outputs 

entity lab3_top_tb is
  -- no inputs or outputs
end entity;


-- The architecture part decribes the behaviour of the test bench

architecture rtl of lab3_top_tb is

   -- declare the state machine component (think of this as a header
   -- specification in C).  This has to match the entity part of your
   -- state machine entity (from state_machine.vhd) exactly.  If you
   -- add pins to state_machine, they need to be reflected here


component lab3_top
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end component;

   -- local signals for your testbench 
       signal CLOCK_50            :  std_logic:= '1';
       signal KEY                 :  std_logic_vector(3 downto 0);
       signal SW                  :  std_logic_vector(17 downto 0);
       signal VGA_R, VGA_G, VGA_B :  std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       signal VGA_HS              :  std_logic;
       signal VGA_VS              :  std_logic;
       signal VGA_BLANK           :  std_logic;
       signal VGA_SYNC            :  std_logic;
       signal VGA_CLK             :  std_logic;

	
begin

	-- instantiate the design-under-test

        dut : lab3_top port map(CLOCK_50, KEY, SW, VGA_R, VGA_G, VGA_B, VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK);

        -- Drive the clock pin.  This creates a square waveform with 
        -- period 2 ns.  Note that this is *not* synthesizable; it doesn't
        -- describe real hardware.  It only describes a pattern to apply to 
        -- the clock input during simulation in Modelsim
        KEY(3) <= '0';
        CLOCK_50 <= not CLOCK_50 after 1 ns;

        -- Resetb starts out at 0 (to reset the state machine), and then goes to 1 at 1ns

        ---resetb_local <= '0', '1' after 1 ns;

        -- Create a pattern for the dir input. You can play with this if you want
        -- to better test your design


end rtl;

