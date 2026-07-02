# Calculadora x86-64

**Disciplina:** Programação para Interfaceamento de Hardware e Software  
**Instituição:** Universidade Estadual de Maringá 
**Dupla:**
- Nome: Letícia Akemi Nakahati Vieira - RA: 140535
- Nome: Pedro Henrique Pereira da Silva - RA: 139781

---

## Descrição

**Trabalho 1 - Calculadora simples:** calculadora implementada em assembly x86-64 com sintaxe AT&T (GAS), sem uso da biblioteca C (libc). Toda a entrada e saída é feita diretamente via syscalls do Linux. O programa aceita operandos reais, realiza operações aritméticas, combinatórias e matemáticas, exibe o resultado e pergunta se o usuário deseja continuar.

**Trabalho 2 - Calculadora com funções:** extensão da calculadora que permite definir variáveis e funções com parâmetros em uma única linha. Suporta chamadas de função com números ou variáveis, consulta de variáveis e expressões mistas. Também implementado sem libc, utilizando apenas syscalls diretas.

---
## Trabalho 1 - Calculadora

## Operações suportadas

| Operador | Operação | Operandos |
|----------|----------|-----------|
| `+` | Soma | dois |
| `-` | Subtração | dois |
| `*` | Multiplicação | dois |
| `/` | Divisão | dois |
| `^` | Exponenciação (base ^ expoente) | dois |
| `c` | Combinação simples C(n, r) | dois |
| `a` | Arranjo simples A(n, r) | dois |
| `l` | Logaritmo (1º operando na base do 2º) | dois |
| `!` | Fatorial | um |
| `i` | Inverso (1 ÷ número) | um |
| `r` | Raiz quadrada | um |
| `p` | Próximo primo ≥ número | um |

---

## Validações

- **Divisão:** informa erro se o divisor for zero.
- **Fatorial, combinação e arranjo:** informa erro se algum operando for negativo ou não inteiro.
- **Combinação e arranjo:** informa erro se n < r.
- **Raiz quadrada:** informa erro se o operando for negativo.
- **Inverso:** informa erro se o operando for zero.
- **Logaritmo:** informa erro se o logaritmando for ≤ 0 ou se a base for ≤ 0 ou igual a 1.

---

## Como compilar e executar

```bash
as -o calculadora.o calculadora.s
ld -o calculadora calculadora.o
./calculadora
```

---

## Exemplos de uso

```
Digite o primeiro operando: 10
Digite o operador: +
Digite o segundo operando: 5
Resultado: 15

Continuar? (s/n): s

Digite o primeiro operando: 9
Digite o operador: r
Resultado: 3

Continuar? (s/n): s

Digite o primeiro operando: 5
Digite o operador: !
Resultado: 120

Continuar? (s/n): s

Digite o primeiro operando: 10
Digite o operador: c
Digite o segundo operando: 3
Resultado: 120

Continuar? (s/n): s

Digite o primeiro operando: 100
Digite o operador: l
Digite o segundo operando: 10
Resultado: 2

Continuar? (s/n): n
```

---


## Trabalho 2 - Calculadora com Funções

### Como compilar e executar

```bash
as -o main.o main.s
as -o operacoes.o operacoes.s
ld -o programa main.o operacoes.o
./programa
```

### Funcionalidades

- Definição de variáveis: `a=8`
- Definição de funções: `f(x)=x+3`, `f(x)=5+x`, `f(x)=x+x`
- Chamada de função com número: `f(4)`
- Chamada de função com variável: `f(a)`
- Consulta de variável: `a`
- Expressão mista: `a+b`, `a+f(10)`
- Todas as operações do Trabalho 1

### Exemplos de uso

```
Digite a expressão: f(x)=x+3
Continuar? (s/n): s
Digite a expressão: f(4)
Resultado: 7.0
Continuar? (s/n): s
Digite a expressão: a=8
Continuar? (s/n): s
Digite a expressão: f(a)
Resultado: 11.0
Continuar? (s/n): s
Digite a expressão: a+f(10)
Resultado: 21.0
Continuar? (s/n): n
```