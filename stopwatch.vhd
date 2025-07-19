library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_STD.all;

entity led_counter is
    Port ( clk    : in  STD_LOGIC; 
           speed : in std_logic;
           reset  : in  STD_LOGIC; 
           ja  : out STD_LOGIC_VECTOR (6 downto 0); 
           jc : out std_logic_vector(6 downto 0)
         );
end led_counter;

architecture Behavioral of led_counter is
--DVSR đại diện cho số chu kỳ xung clock gốc cần đếm để tạo ra một xung chậm hơn (slow clock tick).
--CLOCK GỐC CỦA FPGA LÀ 100MHZ (MỖI 0,5S ĐẾM 1 LẦN VỚI DVSR VÀ 0,25S VỚI DVSR_SPEED)
constant DVSR : integer := 50000000; --DEM XUNG 50MHZ 
constant DVSR_speed : integer := 25000000; --DEM XUNG 25MHZ (MUỐN TĂNG TỐC THÌ DVSR PHẢI NHỎ HƠN )

signal ms_reg,  ms_next : unsigned(26 downto 0); --DÙNG ĐỂ ĐẾM XUNG CLOCK -> CHỌN 2^27 > 50M
signal d0_next, d0_reg : integer range 0 to 9 := 0; --HÀNG ĐƠN VỊ
signal d1_reg, d1_next : integer range 0 to 5 := 0; --HÀNG CHỤC 
signal ms_tick : std_logic; 
signal DVSR_VAL : integer ;

begin
process(clk)
begin
    if (clk'event and clk ='1') then 
        ms_reg <= ms_next;
        d0_reg <= d0_next;            --KHI CÓ CẠNH LÊN CỦA XUNG NHỊP , CẬP NHẬT CÁC THANH GHI = GIÁ TRỊ KẾ TIẾP 
        d1_reg <= d1_next;
        end if;
end process;
    DVSR_VAL <= DVSR when speed = '0' else DVSR_speed ;
    ms_next <= (others => '0') when  reset = '1' or ms_reg = DVSR_VAL  else
                ms_reg + 1 ; --NẾU RESET = 1 MS_REG = 0 CÒN KO THÌ TĂNG THÊM 1
    ms_tick <= '1' when ms_reg = DVSR_VAL else '0'; --BẬT LÊN 1 CHU KÌ KHI  ms_reg ĐẠT DVSR
    
   
process(d0_reg, d1_reg, ms_tick, reset)
begin
    d0_next <= d0_reg ;
    d1_next <= d1_reg ;
    if reset = '1' then
        d0_next <= 0;
        d1_next <= 0;
        elsif ms_tick = '1' then --MS_TICK = 1 ĐÃ ĐỦ 0.5S
            if  (d0_reg /= 9) then    --D0 < 9 TĂNG D0
                d0_next <= d0_reg + 1;
            else d0_next <= 0;    -- D0 = 9 => ĐẶT D0 = 0 ĐỒNG THỜI TĂNG D1 NẾU <5 HOẶC RESET D1 = 0 NẾU D1 = 5
                if(d1_reg /=5) then d1_next <= d1_reg + 1;
                else d1_next <= 0;
                end if;
            end if;
       end if;   
end process; 


process(d0_reg)
begin
    case d0_reg is
        when 0 => ja <= "0111111"; -- 0
        when 1 => ja <= "0000110"; -- 1
        when 2 => ja <= "1011011"; -- 2
        when 3 => ja <= "1001111"; -- 3
        when 4 => ja <= "1100110"; -- 4 
        when 5 => ja <= "1101101"; -- 5 
        when 6 => ja <= "1111101"; -- 6 
        when 7 => ja <= "0000111"; -- 7 
        when 8 => ja <= "1111111"; -- 8
        when 9 => ja <= "1101111"; -- 9 
        when others => ja <= "0000000"; 
    end case;
end process;

process(d1_reg)
begin
    case d1_reg is
        when 0 => jc <= "0111111"; -- 0
        when 1 => jc <= "0000110"; -- 1
        when 2 => jc <= "1011011"; -- 2
        when 3 => jc <= "1001111"; -- 3
        when 4 => jc <= "1100110"; -- 4 
        when 5 => jc <= "1101101"; -- 5 
        when others => jc <= "0000000";
     end case;
end process;

end Behavioral;
