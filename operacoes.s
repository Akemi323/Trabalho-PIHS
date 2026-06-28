.section .text

# Símbolos que vêm do arquivo main.s
.extern buf_op1
.extern buf_op2
.extern operador
.extern imprimir_string
.extern ler_operando
.extern converter_para_float
.extern msg_erro_div
.extern msg_erro_div_l
.extern msg_erro_neg
.extern msg_erro_neg_l
.extern msg_erro_sqrt
.extern msg_erro_sqrt_l
.extern msg_erro_inv
.extern msg_erro_inv_l
.extern msg_erro_log
.extern msg_erro_log_l
.extern msg_erro_ord
.extern msg_erro_ord_l
.extern msg_ponto
.extern const_dez
.extern const_um
.extern const_arred
.extern Lloop

# Tornando as funções visíveis para o linker e para o main.s
.global Lop_soma
.global Lop_sub
.global Lop_mul
.global Lop_div
.global Lop_pow
.global Lop_comb
.global Lop_arr
.global Lop_fat
.global Lop_inv
.global Lop_sqrt
.global Lop_log
.global Lop_primo
.global calcular_fatorial
.global log
.global executar_operacao

Lop_soma:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    addsd %xmm1, %xmm0

    jmp Lop_fim

Lop_sub:
    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    subsd %xmm1, %xmm0

    jmp Lop_fim

Lop_mul:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    mulsd %xmm1, %xmm0

    jmp Lop_fim

Lop_div:
    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2

    ucomisd %xmm2, %xmm1
    je Lerro_div

    divsd %xmm1, %xmm0

    jmp Lop_fim

Lerro_div:
    movq $msg_erro_div, %rsi
    movq $msg_erro_div_l, %rdx
    call imprimir_string

    jmp Lloop

Lop_pow:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0,  %xmm1

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    cvttsd2si %xmm0, %rcx

    movsd const_um(%rip), %xmm0 

    cmpq $0, %rcx
    je Lfim_da_potencia

Lloop_pow:
    mulsd %xmm1, %xmm0
    decq %rcx

    cmp $0, %rcx
    jne Lloop_pow

Lfim_da_potencia:
    jmp Lop_fim

Lop_comb:
    #n! / r! * (n - r)!
    pushq %rbx
    pushq %r12
    pushq %r13

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx #leu n

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %r12 #leu r

    cmpq $0, %rbx
    jl Lerro_fat

    cmpq $0, %r12
    jl Lerro_fat

    cmpq %r12, %rax
    jl Lerro_num_menor

    movq %rbx, %r13
    subq %r12, %r13
    
    movq %rbx, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx
    
    movq %r12, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %r12

    movq %r13, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %r13

    imulq %r12, %r13

    movq %rbx, %rax
    cqo
    idivq %r13

    popq %r13
    popq %r12
    popq %rbx

    cvtsi2sd %rax, %xmm0  # Converte o resultado inteiro de %rax para o float %xmm0
    jmp Lop_fim           # CORRIGIDO: Removido ponto de .Lop_fim

Lop_arr:
    pushq %rbx
    pushq %r12

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx

    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float
    cvttsd2si %xmm0, %rax

    cmpq $0, %rbx
    jl Lerro_fat

    cmpq $0, %rax
    jl Lerro_fat

    cmpq %rax, %rbx
    jl Lerro_num_menor

    movq %rbx, %r12
    subq %rax, %r12 

    movq %rbx, %rax
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %rbx 

    movq %r12, %rax 
    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax
    movq %rax, %r12 

    movq %rbx, %rax 
    cqo
    idivq %r12

    popq %r12
    popq %rbx

    cvtsi2sd %rax, %xmm0  # Converte o resultado inteiro de %rax para o float %xmm0
    jmp Lop_fim           # CORRIGIDO: Removido ponto de .Lop_fim

Lerro_num_menor:          # CORRIGIDO: Removido ponto de .Lerro_num_menor
    movq $msg_erro_ord, %rsi
    movq $msg_erro_ord_l, %rdx
    call imprimir_string

    jmp Lloop

Lop_fat:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    cvttsd2si %xmm0, %rax

    cmpq $0, %rax
    jle Lerro_fat

    cvtsi2sd %rax, %xmm0
    call calcular_fatorial
    cvttsd2si %xmm0, %rax

    jmp Lop_fim

Lerro_fat:
    movq $msg_erro_neg, %rsi
    movq $msg_erro_neg_l, %rdx 
    call imprimir_string

    jmp Lloop

Lop_inv:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    movsd %xmm0, %xmm1
    movsd const_um(%rip), %xmm0

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm1
    je Lerro_inv
    
    divsd %xmm1, %xmm0

    jmp Lop_fim

Lerro_inv:
    movq $msg_erro_inv, %rsi
    movq $msg_erro_inv_l, %rdx
    call imprimir_string

    jmp Lloop

Lop_sqrt:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jb Lsqrt_erro 
    
    sqrtsd %xmm0, %xmm0

    jmp Lop_fim

Lsqrt_erro:
    movq $msg_erro_sqrt, %rsi
    movq $msg_erro_sqrt_l, %rdx
    call imprimir_string

    jmp Lloop

Lop_log:
    movq $buf_op2, %rsi
    call ler_operando
    call converter_para_float

    ucomisd const_um(%rip), %xmm0
    jbe Llog_erro

    call log 
    movsd %xmm0, %xmm1

    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float

    xorpd %xmm2, %xmm2
    ucomisd %xmm2, %xmm0
    jbe Llog_erro 

    ucomisd const_um(%rip), %xmm0
    je Llog_erro
    
    call log
    
    divsd %xmm1, %xmm0
    jmp Lop_fim

Llog_erro:
    movq $msg_erro_log, %rsi
    movq $msg_erro_log_l, %rdx
    call imprimir_string

    jmp Lloop

Lop_primo:
    movq $buf_op1, %rsi
    call ler_operando
    call converter_para_float
    
    addsd const_arred(%rip), %xmm0

    cvttsd2si %xmm0, %rax
    
    cmpq $2, %rax 
    cvtsi2sd %rax, %xmm0  
    jle Lop_fim 

    movq %rax, %rcx

Lprimo_loop:
    movq $2, %r8 

Lprimo_divisor:
    movq %r8, %rax  
    imulq %r8, %rax 

    cmpq %rcx, %rax
    jg Lprimo_fim

    movq %rcx, %rax
    cqo
    idivq %r8

    cmpq $0, %rdx
    je Lprimo_nao
    
    addq $1, %r8
    jmp  Lprimo_divisor

Lprimo_nao:
    incq %rcx
    jmp Lprimo_loop

Lprimo_fim:
    movq %rcx, %rax
    cvtsi2sd %rax, %xmm0

Lop_fim:
    popq %rbp
    ret

calcular_fatorial:
    cvttsd2si %xmm0, %rax
    movq %rax, %rcx
    movq $1, %rax
    cvtsi2sd %rax, %xmm0

    cmpq $1, %rcx
    jle Lfim_fat

Lfat:
    cvtsi2sd %rcx, %xmm1
    mulsd %xmm1, %xmm0
    
    decq %rcx
    cmpq $1, %rcx
    jne Lfat

Lfim_fat:
    ret

log:
    subq $8, %rsp
    movsd %xmm0, (%rsp)

    fldln2
    fldl (%rsp)

    fyl2x
    fstpl (%rsp)
    movsd (%rsp), %xmm0

    addq $8, %rsp
    ret
    