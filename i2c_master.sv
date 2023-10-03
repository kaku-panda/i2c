module i2c_if(
    input         wire clk_400k,
    input         wire clk_800k,
    input  [63:0] wire write_data,
    input  [6:0]  wire slave_addr,
    input         wire rw,
    input  [7:0]  wire register_addr,
    input         wire start,
    input  [2:0]  wire trans,
    output        wire scl,
    inout         wire sda,
    input  [63:0] wire read_data,
    output        wire busy,
    output        wire enable
);

    // input reg
    reg [6:0]  slave_addr_reg;
    reg        rw_reg;
    reg [7:0]  register_addr_reg;
    reg [63:0] write_data_reg;

    // output reg
    reg [63:0] read_data_reg;
    reg        sda_reg;
    reg        scl_reg;

    // ctrl reg
    reg [4:0] state = IDLE;
    reg [4:0] prev_state;
    reg [2:0] data_cnt_reg;
    reg [2:0] trans_cnt_reg;
    reg       wrote_register_addr_flag;

    // STATE
    enum {
        IDLE,
        START,
        PREPARE_SLAVE_ADDR,
        SEND_SLAVE_ADDR,
        PREPARE_ACK,
        WAIT_ACK,
        PREPARE_REG_ADDR,
        WRITE_REG_ADDR,
        PREPARE_DATA,
        WRITE_DATA,
        PREPARE_RESTART,
        RESTART,
        READ_DATA,
        SEND_ACK,
        PREPARE_NACK,
        SEND_NACK,
        STOP
    };

    /////////////////////////////////////////////////////////////////
    /// input register
    /////////////////////////////////////////////////////////////////
    
    // rw_reg
    always_ff@(posedege clk_400k) begin
        if(state == IDLE)begin
            rw_reg            <= 1'b0;
            register_addr_reg <= 8'd0;
            write_data_reg    <= 64'd0;
            read_data_reg     <= read_data_reg;
        end
        if(state == START)begin
            rw_reg            <= rw;
            write_data_reg    <= write_data;
            register_addr_reg <= register_addr;
            read_data_reg     <= 64'd0;
        end
    end

    // slave_addr_reg (slave_addr + R/W)
    always_ff@(posedege clk_400k) begin
        if(state == IDLE)begin
            slave_addr_reg <= 8'd0;
        end
        if(state == START)begin
            slave_addr_reg <= {slave_addr, 0};
        end
        else if(state == RESTART)begin
            slave_addr_reg <= {slave_addr, 1};
        end
    end

    // trans_cnt_reg
    always_ff@(posedege clk_400k)begin
        if(state == START)begin
            trans_cnt_reg <= trans_cnt;
        end
        else if()begin
            trans_cnt_reg <= trans_cnt_reg - 1;
        end
    end

    /////////////////////////////////////////////////////////////////
    /// output register
    /////////////////////////////////////////////////////////////////
    
    // scl
    always_ff@(posedege clk_800k) begin
        if(state == IDLE)begin
            scl_reg <= 1'd0;
        end
        if()begin
            scl_reg <= ~scl_reg;
        end
        else if()begin
            scl_reg <= 1'd0;
        end
    end

    // sda
    always_ff@(posedege clk_400k) begin
        if()begin
            sda_reg <= 1'd0;
        end
        if()begin
            sda_reg <= ~scl_reg;
        end
        else if()begin
            sda_reg <= 1'd0;
        end
    end

    /////////////////////////////////////////////////////////////////
    /// ctrl register
    /////////////////////////////////////////////////////////////////

    // data_cnt_reg
    always_ff@(posedege clk_400k) begin
        if() begin
            data_cnt_reg <= 3'd7;
        end
        else if( && data_cnt_reg != 3'd0) begin
            data_cnt_reg <= data_cnt_reg - 1'd1;
        end    
    end
    
    // wrote_register_addr_flag


    // state
    always_ff@(posedege clk_400k) begin
        case(state)
            IDLE: begin
                if(start)begin
                    state <= START;
                end
            end
            START: begin
                if(sda == 1'b0) begin
                    state <= PREPARE_SLAVE_ADDR;
                end
            end
            PREPARE_SLAVE_ADDR: begin
                state <= SEND_SLAVE_ADDR;
            end
            SEND_SLAVE_ADDR: begin
                if(!data_cnt_reg)begin
                    state <= PREPARE_ACK;
                end
            end
            PREPARE_ACK: begin
                if(rw_reg[0])begin
                    state <= SEND_ACK;
                end
                else begin
                    state <= WAIT_ACK;
                end
            end
            WAIT_ACK: begin
                if(sda == 1'b0)begin
                    if(!wrote_register_addr_flag)begin
                        state <= PREPARE_REG_ADDR;
                    end
                    else begin
                        if(rw_reg) begin
                            state <= PREPARE_RESTART;
                        end
                        else begin
                            state <= PREPARE_DATA;
                        end
                    end
                end
            end
            PREPARE_REG_ADDR: begin
            end
            WRITE_REG_ADDR: begin
            end
            PREPARE_DATA: begin
            end
            WRITE_DATA: begin
            end
            PREPARE_RESTART: begin
                state <= RESTART;
            end
            RESTART: begin
                state <= PREPARE_ACK;
            end
            SEND_ACK: begin
                state <= PREPARE_DATA;
            end
            PREPARE_NACK: begin
                state <= SEND_NACK;
            end
            SEND_NACK: begin
                state <= STOP;
            end
            STOP  : begin
                state <= IDLE;
            end
        endcase
    end

endmodule