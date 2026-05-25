
# Constantes de syscall (Linux x86-64)
.equ SYS_READ,   0
.equ SYS_WRITE,  1
.equ SYS_EXIT,   60
.equ STDIN,      0
.equ STDOUT,     1

# Seção de dados somente leitura
.section .rodata

msg_op1:    .string "Digite o primeiro operando: "
msg_op1_l = . - msg_op1

msg_oper:   .string "Digite o operador: "
msg_oper_l = . - msg_oper

msg_op2:    .string "Digite o segundo operando: "
msg_op2_l = . - msg_op2

msg_res:    .string "Resultado: "
msg_res_l = . - msg_res

msg_cont:   .string "Continuar? (s/n): "
msg_cont_l = . - msg_cont

msg_erro_div:  .string "Erro: divisao por zero\n"
msg_erro_div_l = . - msg_erro_div

msg_erro_neg:  .string "Erro: operando invalido (negativo ou nao inteiro)\n"
msg_erro_neg_l = . - msg_erro_neg

msg_erro_sqrt: .string "Erro: raiz de numero negativo\n"
msg_erro_sqrt_l = . - msg_erro_sqrt

msg_erro_inv:  .string "Erro: inverso de zero\n"
msg_erro_inv_l = . - msg_erro_inv

msg_erro_log:  .string "Erro: logaritmando <= 0 ou base invalida\n"
msg_erro_log_l = . - msg_erro_log

msg_erro_ord:  .string "Erro: n deve ser >= r\n"
msg_erro_ord_l = . - msg_erro_ord

msg_nl:     .string "\n"
msg_nl_l = . - msg_nl

# Seção de dados não inicializados 
.section .bss

buf_in:     .space 64       # buffer de entrada geral
buf_out:    .space 64       # buffer de saída (resultado convertido)
operador:   .space 4        # char do operador

# Seção de código 
.section .text
.global _start

_start:
    call loop_principal

    # Encerrar processo
    movq $SYS_EXIT, %rax
    movq $0,        %rdi
    syscall


# ============================================================
# loop_principal: 
# ============================================================

loop_principal:
    pushq %rbp
    movq  %rsp, %rbp

.Lloop:
    # Pedir e ler primeiro operando 
    # Pedir e ler operador
    # Verificar se é operação unária ou binária
    # Unárias: !, i, r, p -  não lê segundo operando
    # (se binária) Pedir e ler segundo operando

    # Executar a operação 
    call executar_operacao

    # Exibir resultado
    call exibir_resultado

    # Perguntar se continua
    # se sim, jmp .Lloop

    popq %rbp
    ret


# ============================================================
# ler_operando:
# ============================================================
ler_operando:
    pushq %rbp
    movq  %rsp, %rbp

    # Tem q fazer coisa

    popq %rbp
    ret


# ============================================================
# exibir_resultado: 
# ============================================================
exibir_resultado:
    pushq %rbp
    movq  %rsp, %rbp

    # tem q fazer coisa

    popq %rbp
    ret


# ============================================================
# executar_operacao: 
# ============================================================
executar_operacao:
    pushq %rbp
    movq  %rsp, %rbp

    movzbq operador(%rip), %rax   # carrega char do operador

    cmpb $'+', %al
    je   .Lop_soma

    cmpb $'-', %al
    je   .Lop_sub

    cmpb $'*', %al
    je   .Lop_mul

    cmpb $'/', %al
    je   .Lop_div

    cmpb $'^', %al
    je   .Lop_pow

    cmpb $'c', %al
    je   .Lop_comb

    cmpb $'a', %al
    je   .Lop_arr

    cmpb $'!', %al
    je   .Lop_fat

    cmpb $'i', %al
    je   .Lop_inv

    cmpb $'r', %al
    je   .Lop_sqrt

    cmpb $'l', %al
    je   .Lop_log

    cmpb $'p', %al
    je   .Lop_primo

    jmp  .Lop_fim   # operador desconhecido

# Operações binárias
.Lop_soma:
    #fazer aq
    jmp .Lop_fim

.Lop_sub:
    #fazer aq
    jmp .Lop_fim

.Lop_mul:
    #fazer aq
    jmp .Lop_fim

.Lop_div:
    # fazer aq
    jmp .Lop_fim

.Lop_pow:
    # fazer
    jmp .Lop_fim

.Lop_comb:
    # fazer aq
    jmp .Lop_fim

.Lop_arr:
    # fazer aq
    jmp .Lop_fim

.Lop_fat:
    # fazer aq
    jmp .Lop_fim

.Lop_inv:
    # fazer aq
    jmp .Lop_fim

.Lop_sqrt:
    # fazer aq
    jmp .Lop_fim

.Lop_log:
    # fazer aq
    jmp .Lop_fim

.Lop_primo:
    # fazer aq
    jmp .Lop_fim

.Lop_fim:
    popq %rbp
    ret


# ============================================================
# Procedimento auxiliar: imprimir_string
# Entrada: %rsi = endereço da string, %rdx = tamanho
# Destrói: %rax, %rdi (salve antes de chamar se necessário)
# ============================================================
imprimir_string:
    movq $SYS_WRITE, %rax
    movq $STDOUT,    %rdi
    # %rsi e %rdx já devem estar configurados pelo chamador
    syscall
    ret

