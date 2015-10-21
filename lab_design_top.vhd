library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3_top is
  port(CLOCK_50            : in  std_logic;
       KEY                 : in  std_logic_vector(3 downto 0);
       SW                  : in  std_logic_vector(17 downto 0);
       VGA_R, VGA_G, VGA_B : out std_logic_vector(9 downto 0);  -- The outs go to VGA controller
       VGA_HS              : out std_logic;
       VGA_VS              : out std_logic;
       VGA_BLANK           : out std_logic;
       VGA_SYNC            : out std_logic;
       VGA_CLK             : out std_logic);
end lab3_top;

architecture rtl of lab3_top is

 --Component from the Verilog file: vga_adapter.v
  component vga_adapter
    generic(RESOLUTION : string);
    port (resetn                                       : in  std_logic;
          clock                                        : in  std_logic;
          colour                                       : in  std_logic_vector(2 downto 0);
          x                                            : in  std_logic_vector(7 downto 0);
          y                                            : in  std_logic_vector(6 downto 0);
          plot                                         : in  std_logic;
          VGA_R, VGA_G, VGA_B                          : out std_logic_vector(9 downto 0);
          VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK : out std_logic);
  end component;

--signals to vga adapter
  signal resetn, plot     : std_logic;
  signal x                : std_logic_vector(7 downto 0);
  signal y                : std_logic_vector(6 downto 0);
  signal colour           : std_logic_vector(2 downto 0);
  
--signals for next state logic (big FSM)  
  signal CURRENTSTATE     : std_logic_vector(2 downto 0);
  signal NEXTSTATE        : std_logic_vector(2 downto 0);
  
--signals for next state logic (clr FSM)  
  signal CURRENTSTATE_clr : std_logic_vector(1 downto 0);
  signal NEXTSTATE_clr    : std_logic_vector(1 downto 0);
  signal colour_clr       : std_logic_vector(2 downto 0);
  signal INITX, INITY, LOADX, LOADY,
         XDONE, YDONE     : std_logic;
  
--load signals
  signal x0load, sxload, errload, erroutload,
        	dxload, syload, dyload, y0load, y1load,
        	iload, xoutload, youtload : std_logic;

--flag signals
  signal gray_code, draw_line, big_flag, pixel_flag,
         pixel_enable, compare_err, initi, enable_clr,
          clr_done, update_err, sx, sy : std_logic;

--signals representing instances of x and y
  signal x0, x1, x0_out, dx  : unsigned(7 downto 0);
  signal y0, y1, y0_out, dy  : unsigned(6 downto 0);
  signal x_clr               : std_logic_vector(7 downto 0);
  signal y_clr               : std_logic_vector(6 downto 0);
  signal plot_clr            : std_logic;
  
--signal for i counter
  signal i                   : unsigned(3 downto 0);

--signals for integer arithmetic in error computation
  signal err, err_out        : integer;
  
  signal colour_gray         : std_logic_vector(2 downto 0);
  signal plot_pxl            : std_logic;


begin

--DO NOT DELETE VGA ADAPTER 
  vga_u0 : vga_adapter
    generic map(RESOLUTION => "160x120") 
    port map(resetn    => KEY(3),
             clock     => CLOCK_50,
             colour    => colour,
             x         => x,
             y         => y,
             plot      => plot,
             VGA_R     => VGA_R,
             VGA_G     => VGA_G,
             VGA_B     => VGA_B,
             VGA_HS    => VGA_HS,
             VGA_VS    => VGA_VS,
             VGA_BLANK => VGA_BLANK,
             VGA_SYNC  => VGA_SYNC,
             VGA_CLK   => VGA_CLK);
             
resetn<=KEY(3);
x1<=to_unsigned(159, 8);

--OUTER STATE MACHINE LOGIC; SETS FLAG CONDITIONS FOR EACH STATE
process(all)
  begin
    case currentstate is
      when "000" => --While in this state the screen is clearing 
        if (clr_done = '1') then 
--          enable_clr<='0'; -- dont clear screen anymore
          NEXTSTATE<="001"; --go to big loop
          initi<='1'; -- to enable the correct i select
          big_flag<='1'; -- enables big loop process
        else NEXTSTATE <= "000"; --remain in loop
        end if;
        
      when "001" => --big loop state
        big_flag<='0';
        if (i <= 15) then 
          NEXTSTATE<="010"; --next state is gray_code
          gray_code<='1'; --enables gray_code process
          initi<='0'; -- sets initi back down to zero so that it chooses the feedback i instead of the initial i (which is one)
 --         x0load<='1'; y0load<='1'; y1load<='1'; iload<='1'; --all the loads for x0,y0,y1,i to enable a register update of each
        elsif (i>15) then NEXTSTATE<="111"; --exit loop and go to the exit state
        end if;
        
      when "010" => --Gray code state
        NEXTSTATE <= "011"; --next state is draw line state
        gray_code<='0'; -- sets grey code enable back down
 --       colourload<='1'; -- sets load hi for colour to be loaded into its register
        draw_line<='1'; --- enables draw line process
      
      when "011" => --Draw line state
        pixel_enable<='0';
        NEXTSTATE <= "100"; -- next state is update err state
        draw_line<='0';  -- sets flag back down to zero to disable
        update_err<='1'; -- sets flag hi to enable update err process 
--        sxload<='1'; syload<='1'; dxload<='1'; dyload<='1'; -- sets loads hi to enable register update
                
      when "100" => --update err state
        NEXTSTATE <= "101"; -- next state is pixel state
        update_err<='0'; -- sets flag back down to disable process
        pixel_flag<='1'; -- sets flag up to enable pixel process
        erroutload<='0'; -- sets flag hi to load err *remember to set low in reg
        pixel_enable<='1';
--        initx0<='1'; -- sets initx0 hi so that xo is from this state
--        inity0<='1'; -- sets inity0 hi so that yo is from this state
        
      when "101" => -- set pixel state
        pixel_flag<='0'; -- sets pixel flag back down to disable process
        plot_pxl <= '0';
--        loadx<='1'; loady<='1'; plot<='1'; -- sets the stage for writing to vga Q#!@#$!@#!@#$!@#$!@#$!@#$!@#$!@#$!@#$$$$$$$$$$$$$$$$$$$ need to see if colour, x, y, plot is being driven by many signals
        if (x0=x1 and y0=y1) then
          NEXTSTATE <= "001"; -- go to bigloop state
          big_flag<='1'; -- enables big loop process
          xoutload <= '0'; 
          youtload <= '0';
        else NEXTSTATE <= "110"; -- go to comparison state
          compare_err<='1'; -- enables comparison process
          
        end if;
        
      when "110" => -- comparisons state
        compare_err<='0'; -- disables comparison process
        erroutload <= '1';
        xoutload <='1';
        youtload <='1';
        plot_pxl<='1'; -- we dont want to plot here.
        NEXTSTATE <= "101"; -- next state is pixel state
--        erroutload<='1'; -- enables err_out load into register instead of err (tristate driver)
--        x0load<='1'; y0load<='0'; -- enables register update
        pixel_flag<='1'; --enables pixel process in next rising edge clock
        pixel_enable<='0';
--        initx0<='0'; inity0<='0'; -- sets initx0, inity0 so that x0, y0 takes the feedback
        
        
      when "111" => --exit program (stay in this state)
        NEXTSTATE <= "111";
        
      when others => 
        NEXTSTATE <= "000";
        
  end case;
  
end process;

--PROCESS FOR CLEAR SCREEN; ALL DONE
process(all)   
  begin
  --  if (rising_edge(CLOCK_50)) then
        
          case CURRENTSTATE_clr is
            when "00" => 
            enable_clr <= '1';
            INITX<='1'; 
    	       INITY<='1'; 
            LOADY<='1'; 
            PLOT_clr<='0'; 
            NEXTSTATE_clr<="10";
            
           when "01" => 
            INITX<='1'; 
            INITY<='0'; 
            LOADY<='1'; 
            PLOT_clr<='0'; 
            NEXTSTATE_clr<="10";
            
           when "10" => 
            INITX<='0'; 
            INITY<='0'; 
            LOADY<='0'; 
            PLOT_clr<='1'; 
            
            if (YDONE = '1') then NEXTSTATE_clr<="11";
            elsif (YDONE = '0' and XDONE = '1') then NEXTSTATE_clr<="01";
            elsif (XDONE = '0') then NEXTSTATE_clr<="10";
            else NEXTSTATE_clr<="00";
            end if;
           
          when "11" => --all clearing is done, set flags to initialize i and move to the next 3-bit state
            PLOT_clr<='0'; 
            NEXTSTATE_clr<="11";
            enable_clr <= '0';
            clr_done  <= '1';
            
          when others => 
            NEXTSTATE_clr<="00"; -- straight to FIRST state when others
            
        end case;
        
      
 --   end if;
      
  end process;
  
  --PROCESS TO ITERATE THROUGH THE LOOPS FOR CLEARING THE SCREEN; ALL DONE
  process(all)
    variable y_var : unsigned(6 downto 0);
    variable x_var : unsigned(7 downto 0);
     
    begin
      
       if (rising_edge(CLOCK_50)) then
        if (enable_clr = '1') then

         
        if (INITY = '1') then
          y_var := "0000000";
        elsif (LOADY = '1') then
          y_var := y_var + 1;
        end if;
        
        if (INITX = '1') then
          x_var := "00000000";
        else
          x_var := x_var + 1;
          colour_clr<= "000";
        end if;
        
        XDONE <= '0';
        YDONE <= '0';
        
        if (y_var = 119) then
          YDONE <= '1';
        end if;
        
        if (x_var = 159) then
          XDONE <= '1';
        end if;
        
        x_clr<=std_logic_vector(x_var);
        y_clr<=std_logic_vector(y_var);
       
       end if;
     end if;
    
    end process;
    
--BEGIN BIG LOOP DATAPATH   
    process(all)
--      variable y0_var : unsigned (7 downto 0);
    --  variable y1_var : unsigned (7 downto 0);
      variable i_var : unsigned (3 downto 0);
      
      begin
        
        if (rising_edge(CLOCK_50)) then
        
          if (big_flag = '1') then 
            
          --if initi = 1, then set i = 1 and initi = 0
            if (initi = '1') then
              i_var := "0001";
       --       initi <= '0';
            else i_var := i_var + 1;
            end if;
          
--            x0 <= "00000000";
--            y0_var := i * 8;
--            y0 <= y0_var(6 downto 0);
  --          y1_var := 120 - (i * 8);
    --        y1 <= y1_var(6 downto 0);
            
--            x0load <= '1';
--            y0load <= '1';
--            y1load <= '1';
--            iload <= '1';
            i<=i_var;
          end if;
        
        end if;

    end process;
    
--STATE 010: GRAY CODE
process(all)
  variable colour_uns : unsigned(3 downto 0);
  
  begin
    
   if (rising_edge(CLOCK_50)) then
     
     if (gray_code = '1') then
       
       colour_uns := i mod 8;
         colour_gray <= std_logic_vector(colour_uns(2 downto 0));
     end if;  
      
   end if;
  
 end process;
 
 
 --STATE 011: DRAW LINE
 process(all)
   variable dx_var: unsigned(7 downto 0);
   variable dy_var: unsigned(6 downto 0);
  
  begin
    
   if (rising_edge(CLOCK_50)) then
     
     if (draw_line = '1') then
       
       if (x1 < x0) then
          dx_var := x0 - x1;
          sx <= '0'; --negative s to be subtracted later
       else dx_var := x1 - x0;
          sx <= '1'; --positive s to be added later
       end if;
    
       if (y1 < y0) then
         dy_var := y0 - y1;
         sy <= '0'; --negative s to be subtracted later
       else dy_var := y1 - y0;
         sy <= '1'; --positive s to be added later
       end if;  
    

       dx <= dx_var; 
       dy <= dy_var; 
       
--       sxload <= '1';
--       syload <= '1';
--       dxload <= '1';
--       dyload <= '1';
     
     end if;  
      
   end if;
  
 end process;
 
--STATE 100: UPDATE ERR
 process(all)
   variable dx_int: integer;
   variable dy_int: integer;
   
   begin
     
     if(rising_edge(CLOCK_50)) then
     
      if (update_err = '1') then
        
       dx_int := to_integer(dx);
       dy_int := to_integer(dy);      
       err <= dx_int - dy_int;
       
--       errload <= '1';
--       erroutload<='0';         
      end if;
      
     end if;
     
   end process;
   
--STATE 101: UPDATE PIXEL
 process(all)
   
   begin
     
     if (rising_edge(CLOCK_50)) then
       
       if (pixel_flag = '1') then
         
--         if (initx = '1') then  
--         end if; 
        
--         if (inity = '1') then
--         end if;

   --      pixel_enable <= '1';
         
       end if;
       
     end if;
     
 
 end process;
 
 
--STATE 110: COMPARE ERR
process(all)
  variable e2: integer; --doesn't need to exist outside of the process
  variable dy_int: integer range 0 to 159; 
  variable dx_int: integer;
  variable dy_neg: integer; -- will hold dy_int * (-1)
  
  begin
    
    if (rising_edge(CLOCK_50)) then
      
      if (compare_err = '1') then
        
          --We are in this state assuming that x0 != x1 and y0 != y1. This was checked externally.
          if (erroutload='0') then
            e2 := 2*err;
          else e2 := 2*err_out;
          end if;
          dy_int := to_integer(dy); --cast to integer to be able to handle negative numbers
          dx_int := to_integer(dx); --cast to integer to be able to handle negative numbers
          dy_neg := dy_int*(-1); --multiply integer by negative one
  
          --If flag sx is 1, we add 1 to the corresponding x output. Otherwise subtract 1.
          if((e2 > dy_neg) and (sx = '1')) then
            err_out <= err - dy_int;
            x0_out <= x0 + "0000001";
          elsif((e2 > dy_neg) and (sx = '0')) then
            err_out <= err - dy_int;
            x0_out <= x0 - "0000001";
          end if;
      
        --If flag sy is 1, we add 1 to the corresponding y output. Otherwise subtract 1.      
          if((e2 < dx_int) and (sy = '1')) then
            err_out <= err + dx_int;
            y0_out <= y0 + "0000001";
          elsif((e2 < dx_int) and (sy = '0')) then
            err_out <= err + dx_int;
            y0_out <= y0 - "0000001";
          end if;
          
--          xoutload <= '1';
--          youtload <= '1';
    --      erroutload <= '1';
          
        end if;
        
      end if; 
    
  end process;
    

--RESET AND NEXT STATE CLOCK LOGIC; ALL DONE      
process(CLOCK_50) -- nextstate on rising edge
  begin
    if (rising_edge(CLOCK_50)) then
        if (resetn = '1') then -- reset logic
          CURRENTSTATE<="000";
          CURRENTSTATE_clr <= "00";
        else
          CURRENTSTATE<=NEXTSTATE;
          CURRENTSTATE_clr<=NEXTSTATE_clr;
        end if;
    end if;
end process;

-----------------------------------------------------------------------------------------
--Registers
--------------------------------------------------------------------------
process(CLOCK_50)
  variable y0_var : unsigned (7 downto 0);
  variable y1_var : unsigned (7 downto 0);
     
  begin
  if (rising_edge(CLOCK_50)) then
      if (xoutload='1') then--x0 reg
        x0<=x0_out;
      else
        x0<="00000000";
      end if;
      if (youtload='1') then--y0 reg
        y0<=y0_out;
     else
        y0_var := i * 8;
        y0 <= y0_var(6 downto 0);
        y1_var := 120 - (i * 8);
        y1 <= y1_var(6 downto 0);
      end if;
      if (enable_clr='1') then -- x reg and y reg
        x<=x_clr;
        y<=y_clr;
        colour<=colour_clr;
        plot<=plot_clr;
      else
        x<=std_logic_vector(x0);
        y<=std_logic_vector(y0);
        if (pixel_enable = '1') then
        plot<= not plot_pxl;
         end if;
        colour<=colour_gray;
      end if;
   end if;
end process;


end RTL;

