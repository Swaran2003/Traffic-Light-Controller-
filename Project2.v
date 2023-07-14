module traffic_light(light_highway, light_farm, C, clk, rst_n);
  parameter HGRE_FRED=2'b00,
            HYEL_FRED=2'b01,
            HRED_FGRE=2'b10,
            HRED_FYEL=2'b11;

  input C, clk, rst_n;
  output reg [2:0] light_highway, light_farm;
  reg [27:0] count = 0, count_delay = 0;
  reg delay10s = 0, delay3s1 = 0, delay3s2 = 0, RED_count_en = 0, YELLOW_count_en1 = 0, YELLOW_count_en2 = 0;
  wire clk_enable;
  reg [1:0] state, next_state;

  // Sequential logic to update the state
  always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      state <= 2'b00;  // Reset state
    else
      state <= next_state;
  end

  // Combinational logic to determine the next state and control the traffic lights
  always @(*) begin
    case(state)
      HGRE_FRED: begin
        RED_count_en = 0;
        YELLOW_count_en1 = 0;
        YELLOW_count_en2 = 0;
        light_highway = 3'b001;  // Green on highway
        light_farm = 3'b100;     // Red on farm road
        if (C)
          next_state = HYEL_FRED;  // Transition to the next state if vehicle detected on farm road
        else
          next_state = HGRE_FRED;  // Stay in the same state
      end
      HYEL_FRED: begin
        light_highway = 3'b010;   // Yellow on highway
        light_farm = 3'b100;      // Red on farm road
        RED_count_en = 0;
        YELLOW_count_en1 = 1;
        YELLOW_count_en2 = 0;
        if (delay3s1)
          next_state = HRED_FGRE;  // Transition to the next state after 3 seconds of yellow
        else
          next_state = HYEL_FRED;  // Stay in the same state
      end
      HRED_FGRE: begin
        light_highway = 3'b100;   // Red on highway
        light_farm = 3'b001;      // Green on farm road
        RED_count_en = 1;
        YELLOW_count_en1 = 0;
        YELLOW_count_en2 = 0;
        if (delay10s)
          next_state = HRED_FYEL;  // Transition to the next state after 10 seconds of red
        else
          next_state = HRED_FGRE;  // Stay in the same state
      end
      HRED_FYEL: begin
        light_highway = 3'b100;   // Red on highway
        light_farm = 3'b010;      // Yellow on farm road
        RED_count_en = 0;
        YELLOW_count_en1 = 0;
        YELLOW_count_en2 = 1;
        if (delay3s2)
          next_state = HGRE_FRED;  // Transition to the next state after 3 seconds of yellow
        else
          next_state = HRED_FYEL;  // Stay in the same state
      end
      default: next_state = HGRE_FRED;
    endcase
  end

  // Sequential logic to create delay counts for red and yellow lights
  always @(posedge clk) begin
    if (clk_enable == 1) begin
      if (RED_count_en || YELLOW_count_en1 || YELLOW_count_en2)
        count_delay <= count_delay + 1;
      if ((count_delay == 9) && RED_count_en) begin
        delay10s = 1;
        delay3s1 = 0;
        delay3s2 = 0;
        count_delay <= 0;
      end else if ((count_delay == 2) && YELLOW_count_en1) begin
        delay10s = 0;
        delay3s1 = 1;
        delay3s2 = 0;
        count_delay <= 0;
      end else if ((count_delay == 2) && YELLOW_count_en2) begin
        delay10s = 0;
        delay3s1 = 0;
        delay3s2 = 1;
        count_delay <= 0;
      end else begin
        delay10s = 0;
        delay3s1 = 0;
        delay3s2 = 0;
      end
    end
  end

  // Sequential logic to create a 1-second clock enable signal
  always @(posedge clk) begin
    count <= count + 1;
    if (count == 3)
      count <= 0;
  end

  assign clk_enable = count == 3 ? 1 : 0;  // Enable signal is high for 1 second
endmodule
