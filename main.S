#include <avr/io.h>
#include <avr/interrupt.h>

.section .text
char_map: .byte 0x71, 0x7C, 0x38, 0x50 

.section .bss
    blink_threshold: .space 4 
    blink_counter:   .space 4 
    led_state:       .space 1 
    min_dist:        .space 1 
    min_id:          .space 1 
    
    temp_min_dist:   .space 1
    temp_min_id:     .space 1
    
    tick_counter:    .space 1

.section .text
.global main
.global TIMER0_COMPA_vect

main:
    ldi r16, lo8(RAMEND)
    out _SFR_IO_ADDR(SPL), r16
    ldi r16, hi8(RAMEND)
    out _SFR_IO_ADDR(SPH), r16

    ldi r16, 0x1F
    out _SFR_IO_ADDR(DDRB), r16
    out _SFR_IO_ADDR(PORTB), r16 

    ldi r16, 0x1C
    out _SFR_IO_ADDR(DDRD), r16

    ldi r16, 0x10
    out _SFR_IO_ADDR(DDRC), r16

    ldi r16, 0
    sts UBRR0H, r16
    ldi r16, 103        
    sts UBRR0L, r16
    ldi r16, (1<<TXEN0) 
    sts UCSR0B, r16
    ldi r16, (1<<UCSZ01) | (1<<UCSZ00) 
    sts UCSR0C, r16

    ldi r16, 124        
    out _SFR_IO_ADDR(OCR0A), r16
    ldi r16, (1<<WGM01) 
    out _SFR_IO_ADDR(TCCR0A), r16
    ldi r16, (1<<CS01) | (1<<CS00) 
    out _SFR_IO_ADDR(TCCR0B), r16
    ldi r16, (1<<OCIE0A)
    sts TIMSK0, r16

    clr r16
    sts led_state, r16  
    sts tick_counter, r16
    sei                 

main_loop:
    ldi r16, 255
    sts temp_min_dist, r16

    ldi r24, 0          
    ldi r25, 0x01       
    rcall read_sensor_and_update

    ldi r24, 1
    ldi r25, 0x02
    rcall read_sensor_and_update

    ldi r24, 2
    ldi r25, 0x04
    rcall read_sensor_and_update

    ldi r24, 3
    ldi r25, 0x08
    rcall read_sensor_and_update
    lds r16, temp_min_dist
    sts min_dist, r16
    lds r16, temp_min_id
    sts min_id, r16

    rcall print_portb_status

    lds r16, min_dist
    cpi r16, 35         
    brsh status_aman    

status_bahaya:
    ldi ZL, lo8(char_map)
    ldi ZH, hi8(char_map)
    lds r16, min_id
    add ZL, r16
    brcc no_carry_z
    inc ZH
no_carry_z:
    lpm r16, Z          
    rcall shift_out_7seg
    rjmp delay_siklus

status_aman:
    ldi r16, 0x00
    rcall shift_out_7seg

delay_siklus:
    ldi r20, 15
delay_loop_outer:
    ldi r21, 255
delay_loop_inner:
    ldi r22, 255
delay_loop_core:
    dec r22
    brne delay_loop_core
    dec r21
    brne delay_loop_inner
    dec r20
    brne delay_loop_outer
    rjmp main_loop

read_sensor_and_update:
    ldi r18, 0
    ldi r19, 0
wait_pre_echo:
    in r16, _SFR_IO_ADDR(PINC)
    and r16, r25
    breq trigger_pulse
    dec r18
    brne wait_pre_echo
    dec r19
    brne wait_pre_echo
    rjmp sensor_timeout 

trigger_pulse:
    sbi _SFR_IO_ADDR(PORTC), 4
    ldi r16, 53     
trigger_delay:
    dec r16
    brne trigger_delay
    cbi _SFR_IO_ADDR(PORTC), 4

    ldi r18, 0
    ldi r19, 0
wait_echo_high:
    in r16, _SFR_IO_ADDR(PINC)
    and r16, r25
    brne echo_started
    dec r18
    brne wait_echo_high
    dec r19
    brne wait_echo_high
    rjmp sensor_timeout

echo_started:
    clr r16
    sts TCNT1H, r16
    sts TCNT1L, r16
    ldi r16, (1<<CS11) | (1<<CS10) 
    sts TCCR1B, r16

wait_echo_low:
    in r16, _SFR_IO_ADDR(PINC)
    and r16, r25
    breq echo_ended 
    lds r17, TCNT1L
    lds r16, TCNT1H
    cpi r16, 12             
    brsh echo_ended_timeout
    rjmp wait_echo_low

echo_ended_timeout:
    clr r16
    sts TCCR1B, r16
    rjmp sensor_timeout

echo_ended:
    clr r16
    sts TCCR1B, r16
    lds r17, TCNT1L         
    lds r16, TCNT1H         
    cpi r16, 12
    brsh sensor_timeout

    swap r17                
    andi r17, 0x0F          
    swap r16
    andi r16, 0xF0
    or r17, r16             
    rjmp process_distance

sensor_timeout:
    ldi r17, 255

process_distance:
    mov r16, r24
    subi r16, 208
    rcall print_char
    ldi r16, ':'
    rcall print_char
    mov r16, r17
    rcall print_hex
    ldi r16, ' ' 
    rcall print_char

    cpi r17, 35             
    brsh batasi_jarak
    cpi r17, 10             
    brlo solid_jarak
    mov r18, r17            
    rjmp simpan_threshold

batasi_jarak:
    ldi r17, 255            
    ldi r18, 255            
    rjmp simpan_threshold

solid_jarak:
    ldi r18, 0              

simpan_threshold:
    ldi YL, lo8(blink_threshold)
    ldi YH, hi8(blink_threshold)
    add YL, r24             
    brcc no_carry_thresh
    inc YH
no_carry_thresh:
    st Y, r18               
    lds r16, temp_min_dist
    cp r17, r16
    brsh skip_min
    sts temp_min_dist, r17       
    sts temp_min_id, r24         
skip_min:
    ldi r20, 5
delay_settle_outer:
    ldi r21, 255
delay_settle_inner:
    ldi r22, 255
delay_settle_core:
    dec r22
    brne delay_settle_core
    dec r21
    brne delay_settle_inner
    dec r20
    brne delay_settle_outer
    ret

print_portb_status:
    ldi r16, '|'
    rcall print_char
    ldi r16, ' '
    rcall print_char
    ldi r16, 'B'
    rcall print_char
    ldi r16, ':'
    rcall print_char
    
    lds r16, min_dist
    cpi r16, 35
    brsh print_b0
    
    lds r18, led_state
    lds r17, min_id
    mov r19, r17
    ldi r21, 1
find_b_print:
    cpi r19, 0
    breq eval_b_print
    lsl r21
    dec r19
    rjmp find_b_print
eval_b_print:
    and r21, r18
    breq print_b0
    ldi r16, '1'
    rjmp print_b_out
print_b0:
    ldi r16, '0'
print_b_out:
    rcall print_char
    
    ldi r16, ' '
    rcall print_char
    ldi r16, 'L'
    rcall print_char
    ldi r16, ':'
    rcall print_char
    
    in r17, _SFR_IO_ADDR(PORTB) 
    mov r16, r17
    andi r16, 0x08
    rcall print_bit_char
    mov r16, r17
    andi r16, 0x04
    rcall print_bit_char
    mov r16, r17
    andi r16, 0x02
    rcall print_bit_char
    mov r16, r17
    andi r16, 0x01
    rcall print_bit_char

    ldi r16, ' '
    rcall print_char
    ldi r16, '|'
    rcall print_char
    ldi r16, ' '
    rcall print_char
    ldi r16, 'I'
    rcall print_char
    ldi r16, 'n'
    rcall print_char
    ldi r16, 't'
    rcall print_char
    ldi r16, ':'
    rcall print_char
    
    lds r16, min_id
    ldi ZL, lo8(blink_threshold)
    ldi ZH, hi8(blink_threshold)
    add ZL, r16
    clr r17
    adc ZH, r17
    ld r16, Z
    rcall print_hex
    
    ldi r16, 10             
    rcall print_char
    ret

print_bit_char:
    breq pbc_0
    ldi r16, '1'
    rjmp pbc_out
pbc_0:
    ldi r16, '0'
pbc_out:
    rcall print_char
    ret

print_char:
    push r17
wait_tx:
    lds r17, UCSR0A
    sbrs r17, UDRE0
    rjmp wait_tx
    sts UDR0, r16
    pop r17
    ret
    
print_hex:
    push r16
    swap r16
    rcall print_nibble
    pop r16
    rcall print_nibble
    ret
    
print_nibble:
    andi r16, 0x0F
    cpi r16, 10
    brlo is_digit
    subi r16, 249           
is_digit:
    subi r16, 208           
    rcall print_char
    ret

shift_out_7seg:
    cbi _SFR_IO_ADDR(PORTD), 4  
    ldi r18, 8                  
shift_loop:
    cbi _SFR_IO_ADDR(PORTD), 2  
    sbrc r16, 7                 
    sbi _SFR_IO_ADDR(PORTD), 2  
    sbi _SFR_IO_ADDR(PORTD), 3  
    cbi _SFR_IO_ADDR(PORTD), 3  
    lsl r16                     
    dec r18
    brne shift_loop
    sbi _SFR_IO_ADDR(PORTD), 4  
    ret

TIMER0_COMPA_vect:
    push r16
    in r16, _SFR_IO_ADDR(SREG)
    push r16
    push r17
    push r18
    push r19
    push r20
    push r21
    push r24
    push r25
    push XL
    push XH
    push YL
    push YH

    lds r16, min_dist
    cpi r16, 35             
    brsh buzzer_off
    
    lds r18, led_state
    lds r17, min_id
    mov r19, r17
    ldi r21, 1
check_buzz_bit:
    cpi r19, 0
    breq eval_buzz_bit
    lsl r21
    dec r19
    rjmp check_buzz_bit
eval_buzz_bit:
    and r21, r18
    breq buzzer_off
    
    in r16, _SFR_IO_ADDR(PORTB)
    ldi r17, 0x10
    eor r16, r17
    out _SFR_IO_ADDR(PORTB), r16
    rjmp handle_leds
    
buzzer_off:
    cbi _SFR_IO_ADDR(PORTB), 4
    
handle_leds:
    lds r16, tick_counter
    inc r16
    cpi r16, 20
    breq do_led_logic
    sts tick_counter, r16
    rjmp isr_exit
    
do_led_logic:
    clr r16
    sts tick_counter, r16

    ldi XL, lo8(blink_counter)
    ldi XH, hi8(blink_counter)
    ldi YL, lo8(blink_threshold)
    ldi YH, hi8(blink_threshold)
    
    lds r18, led_state      
    ldi r19, 0              

isr_loop:
    ld r16, X               
    ld r17, Y               
    
    cpi r17, 250            
    brsh matikan_led_ini
    cpi r17, 0              
    breq nyalakan_led_solid

    dec r16                 
    brne simpan_counter     
    
    mov r20, r19            
    ldi r21, 1              
geser_bit:
    cpi r20, 0
    breq eksekusi_toggle
    lsl r21
    dec r20
    rjmp geser_bit
eksekusi_toggle:
    eor r18, r21            
    mov r16, r17            
    rjmp simpan_counter

nyalakan_led_solid:
    mov r20, r19
    ldi r21, 1
geser_nyala:
    cpi r20, 0
    breq eksekusi_nyala
    lsl r21
    dec r20
    rjmp geser_nyala
eksekusi_nyala:
    or r18, r21             
    rjmp simpan_counter

matikan_led_ini:
    mov r20, r19
    ldi r21, 1
geser_mati:
    cpi r20, 0
    breq eksekusi_mati
    lsl r21
    dec r20
    rjmp geser_mati
eksekusi_mati:
    com r21                 
    and r18, r21            

simpan_counter:
    st X+, r16              
    adiw YL, 1              
    inc r19
    cpi r19, 4
    brne isr_loop

    sts led_state, r18      
    
output_portb:
    in r17, _SFR_IO_ADDR(PORTB)
    andi r17, 0xF0  
    andi r18, 0x0F  
    or r18, r17
    out _SFR_IO_ADDR(PORTB), r18

isr_exit:
    pop YH
    pop YL
    pop XH
    pop XL
    pop r25
    pop r24
    pop r21
    pop r20
    pop r19
    pop r18
    pop r17
    pop r16
    out _SFR_IO_ADDR(SREG), r16
    pop r16
    reti