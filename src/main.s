.section .bss
    id: .space 4

    corrente: .int 0
    precedente: .int 0

    # BSS PER GESTIONE FILE
        nomefile: .space 100 
        nomeoutput: .space 100
    
    bufferlettura: .space 50  ##spazio per il buffer di input
    
    fd: .int 0                  ##file descriptor

    # BSS PER DIVIDERE PARAMETRI E INSERIMENTO IN PILA
    cont_char: .int 0
    uno: .int 0
    due: .int 0
    nr_ordini: .int 0
    nr_par: .int 0
    esci: .int 0
    ris_syc: .int 0

    # BSS PER GESTIONE BUBBLESORT
    penalty: .long 0
    conclusion: .long 0  
         
    nrordini: .long 0
    cont: .long 0
    espv: .long 0        ##gli do l'indirizzo di esp
    temp: .long 0

    # BSS GESTIONE INPUT
    nalgoritmo: .space 4
    lun: .long 0
    val: .byte 0

    # STAMPA SCADENZA
    id_pila: .space 4
    inizio_produz: .space 8
    conclus_string: .space 8
    
    # PENALITA
    scadenza: .int 0
    totPenality: .int 0
    penality_string: .space 8

    lunghezza_nfile: .int 0
    
.section .data
    # DATA MENU
    menuStr: .string "\nselezionare il tipo di algoritmo \n0)ESCI\n1)EDF\n2)HPF\n"
    menu_lenght: .long . - menuStr
   
    # DATA GESTIONE INPUT
    strout: .string " \n" 

    # EDF 
    strEdf: .string "Pianificazione EDF:\n"
    strEdf_length: .long . - strEdf

    # HPF
    strHpf: .string "Pianificazione HPF:\n" 
    strHpf_length: .long . - strHpf  

    # conclusione
    conclusione: .string "Conclusione: " 
    concl_length: .long . - conclusione  

    # penality
    penality: .string "Penalty: " 
    penality_length: .long . - penality 

    # ERRORI
    # errore inserimento input menu
    str_err_input_menu: .string "Error: inserimento INPUT MENU (input validi: 0, 1, 2)" 
    str_err_input_menu_length: .long . - str_err_input_menu 

    # errore valore id
    str_err_val_file: .string "Error: File con valori fuori dal range consentito" 
    str_err_val_file_length: .long . - str_err_val_file 

    duePunti: .string ":"
    newLine: .string "\n"


.section .text
    .global _start


# LEGGE IL NUMERO DI ARGOMENTI E L'ARRAY ARGOMENTO DALLO STACK
_start:
    movl (%esp), %ebx         
    cmpl $1, %ebx          # Controlla se c'è almeno un argomento oltre al nome del programma
    jle fine               
    movl 8(%esp), %ecx     
    movl %ecx, %esi        
    leal nomefile, %edi

    copia:
    movb (%esi), %al       
    movb %al, (%edi)       
    incl %esi              
    incl %edi              
    cmpb $0, %al           
    jne copia              

    movl $0, (%edi)

# APERTURA FILE
aprifile:
    mov $5, %eax              # sys_open (numero della syscall per open)
    mov $nomefile, %ebx       
    mov $0, %ecx              
    int $0x80                 

    cmp $0, %eax        
    jl err_input_menu
    mov %eax, fd        

    movl $0, %esi
    
    # inizializzo valori per find_comma
    movl $id, %edi
    movl $0, %ecx
    movl $0, cont_char
 
# LEGGE UN CARATTERE DAL FILE
leggichar:
    mov $3, %eax        # syscall read
    mov fd, %ebx        
    mov $bufferlettura, %ecx   
    mov $1, %edx        
    int $0x80           

    movl %eax, %ecx

    movl $bufferlettura, %esi        
    movb (%esi), %al                    

    movb nr_par, %bl    
    cmpb $4, %bl
    je inc_n_ord  

    cmpb $44, %al
    je num_char_par
    
    cmpb $13, %al
    je num_char_par

    cmpl $0, %ecx
    je finefile
    
# CARICA IN PILA I VALORI LETTI DAL FILE
pusha:
    incl cont_char
 
    movzbl %al, %eax     
    pushl %eax
    jmp leggichar

# CONTROLLA DA QUANTI NUMERI E' COMPOSTO IL PARAMETRO
num_char_par:
    incl nr_par
    movl %ecx, ris_syc
    
    movl cont_char, %ecx
    cmpl $1, %ecx
    je OneChar
    cmpl $2, %ecx
    je TwoChar
    cmpl $3, %ecx
    je ThreeChar

    jmp chiudifile

inc_n_ord:
    incl nr_ordini
    movl $0, nr_par
    jmp leggichar

# TRASFORMA IN INTERO I VALORI COMPOSTI DA 1 CARATTERE
OneChar:
    popl %eax
    subl $0x30, %eax
    pushl %eax

    movl $0, cont_char
    jmp checkValori

# TRASFORMA IN INTERO I VALORI COMPOSTI DA 2 CARATTERI
TwoChar:
    popl %eax
    subl $0x30, %eax
    movl %eax, uno
    
    popl %eax
    subl $0x30, %eax
    
    mov $10, %bx             # Carico il valore 10 nel registro %bx
    mul %bx                  # esegue %ax = %ax * %bx

    addl uno, %eax
    pushl %eax

    jmp checkValori
    
# TRASFORMA IN INTERO I VALORI COMPOSTI DA 3 CARATTERI
ThreeChar:
    # tolgo dalla pila la cifra meno significativa         push 1 2 3,    pop 3 2 1
    popl %eax
    subl $0x30, %eax
    movl %eax, due

    # tolgo dalla pila la cifra centrale e la moltiplico *10         
    popl %eax
    subl $0x30, %eax

    mov $10, %bx             
    mul %bx 

    movl %eax, uno

    popl %eax
    subl $0x30, %eax

    mov $100, %bx           
    mul %bx

    addl due, %eax
    addl uno, %eax

    pushl %eax
  jmp checkValori

# IN BASE AL PARAMETRO (id, durata, scadenza, priorita) CONTROLLA CHE RISPETTA IL RANGE 
checkValori:
    movl $0, cont_char
    cmpl $1, nr_par
    je check_id
    cmpl $2, nr_par
    je check_dur
    cmpl $3, nr_par
    je check_scad
    cmpl $4, nr_par
    je check_prior
 
# CONTROLLO VALORE ID
check_id:
    cmpl $127, %eax 
    jg err_val_file
    
    jmp leggichar
    
# CONTROLLO VALORE DURATA
check_dur:
    cmpl $10, %eax 
    jg err_val_file

    jmp leggichar

# CONTROLLO VALORE SCADENZA
check_scad:
    cmpl $100, %eax 
    jg err_val_file

    jmp leggichar

# CONTROLLO VALORE PRIORITA
check_prior:
    cmpl $5, %eax 
    jg err_val_file

    cmpl $0, ris_syc
    je chiudifile
    jmp leggichar

finefile:
    movl $1, esci
    jmp num_char_par

# CHIUDE FILE
chiudifile:
    mov $6, %eax        # syscall close
    mov %ebx, %ecx      
    int $0x80           

# AZZERA NFILE
azzera_nfile:
    movl $0, nomefile(%ebx)
    decl %ebx
    cmpl $0, %ebx
    jne azzera_nfile

# STAMPA MENU
menu:
    movl $4, %eax           
    movl $1, %ebx           
    leal menuStr, %ecx      
    movl menu_lenght, %edx   
    int $0x80

# INPUT MENU
menuInput:
    ##LETTURA INPUT
    movl $3, %eax     
    movl $0, %ebx       
    leal nalgoritmo, %ecx     
    movl $3, %edx         
    int $0x80
    
    movl $1, %ebx
    movb nalgoritmo, %al 
    
    cmpl $10, nalgoritmo(%ebx) 
    jne fine

    subb $0x30, %al         
    movzbl %al, %eax
    movl %eax, val

    cmpl $1, %eax
    je edf
    cmpl $2, %eax
    je hpf
    
    jmp fine

# EDF
edf:
    
    addl $1, nr_ordini       
    movl nr_ordini, %ecx
    movl %esp, %ebx     
    leal 4(%ebx), %eax

# METTE IN PILA IL PUNTATORE ALLA SCADENZA
scad:
    pushl %eax
    leal 16(%eax), %eax

    decl %ecx
    cmpl $0, %ecx
    jne scad

    movl $0, %eax              # contatore, nr di non scambi
    movl $0, %ecx             # serve per fare i compare
    movl (%esp), %ebx         # ebx sarà il nostro stack pointer 
    movl 4(%esp), %edx        # edx lo stack pointer all'indirizzo successivo in pila
    movl %esp, espv           # la etichetta esp, contiente l'indirizzo effettivo di esp, quindi (esp) restituisce l'ulitmo valore messo in pila

# ALGORITMO BUBBLE SORT PER ORDINAMENTO PUNTATORI SCADENZA
bubble_sort:
    movl $0, corrente
    movl $0, precedente

    incl cont       
    movl nr_ordini, %ecx
    cmpl %ecx, cont
    je Output_edf 
    
    # confronto contenuto esp e quello della posizione successiva (vers la ase)
    movl (%ebx), %ecx

    cmpl %ecx, (%edx)
    
    jl scambio     
    je OrdinaPriorita

# NON AVVIENE LO SCAMBIO SPOSTO I DUE PUNTATORI AGLI INDIRIZZI SUCCESSIVI (+4)
noscambioedf:
    addl $4, %eax
    movl %eax, temp
    movl espv, %eax

    addl $4, %eax                
    movl (%eax), %ebx        
    addl $4, %eax                
    movl (%eax), %edx    
    subl $4, %eax                    
    movl %eax, espv
    movl temp, %eax

    jmp bubble_sort

# AVVIENE LO SCAMBIO TORNO A PUNTARE AL PRIMO E SECONDO VALORE (dalla cima) DELLA PILA
scambio:
    movl %eax, temp
    movl espv, %eax

    movl %edx, (%eax)          
    addl $4, %eax
    movl %ebx, (%eax)
    subl $4, %eax

    movl %eax, espv            
    movl temp, %eax

    subl %eax, espv

    movl (%esp), %ebx     
    movl 4(%esp), %edx      
    
    movl $0, %eax
    movl $0, cont

    jmp bubble_sort

# CONTROLLA CHI HA PRIORITA' MAGGIORE IN CASO DI SCADENZA UGUALE
OrdinaPriorita:
    movl %eax, temp
    leal -4(%edx), %edx    
    movl (%edx), %eax
    cmpl -4(%ebx), %edx 
    leal 4(%edx), %edx         
    movl temp, %eax
    jg scambio                  

    jmp noscambioedf


# STAMPA PIANIFICAZIONE EDF
Output_edf:   
    movl $4, %eax           
    movl $1, %ebx           
    leal strEdf, %ecx      
    movl strEdf_length, %edx  
    int $0x80

    movl nr_ordini, %edx
    movl $0, cont

    jmp output_id
    
# HPF
hpf:
    addl $1, nr_ordini          
    movl nr_ordini, %ecx
    movl %esp, %ebx     
    leal (%ebx), %eax       


# METTE IN PILA IL PUNTATORE ALLA PRIORITA
prior:  
    pushl %eax
    leal 16(%eax), %eax

    decl %ecx
    cmpl $0, %ecx
    jne prior

  
    movl $0, %eax            # contatore, nr di non scambi
    movl $0, %ecx            # serve per fare i compare
    movl (%esp), %ebx        # ebx sarà il nostro stack pointer 
    movl 4(%esp), %edx       # edx lo stack pointer all'indirizzo successivo in pila
    movl %esp, espv          # la etichetta esp, contiente l'indirizzo effettivo di esp, quindi (esp) restituisce l'ulitmo valore messo in pila

# ALGORITMO BUBBLE SORT PER ORDINAMENTO PUNTATORI PRIORIT
bubble_sortHPF:

    incl cont      
    movl nr_ordini, %ecx
    cmpl %ecx, cont
    je Output_hpf   

    # confronto contenuto esp e quello della posizione successiva (vers la ase)
    movl (%ebx), %ecx

    cmpl %ecx, (%edx)
    
    jg scampioHPF     
    je OrdinaScad

# NON AVVIENE LO SCAMBIO SPOSTO I DUE PUNTATORI AGLI INDIRIZZI SUCCESSIVI (+4)
noscambio:
    addl $4, %eax
    movl %eax, temp
    movl espv, %eax

    addl $4, %eax              
    movl (%eax), %ebx        
    addl $4, %eax                
    movl (%eax), %edx    
    subl $4, %eax                   
    movl %eax, espv
    movl temp, %eax

    jmp bubble_sortHPF

# AVVIENE LO SCAMBIO TORNO A PUNTARE AL PRIMO E SECONDO VALORE (dalla cima) DELLA PILA
scampioHPF:
    movl %eax, temp
    movl espv, %eax

    movl %edx, (%eax)           
    addl $4, %eax
    movl %ebx, (%eax)
    subl $4, %eax

    movl %eax, espv             
    movl temp, %eax

    subl %eax, espv         

    movl (%esp), %ebx     
    movl 4(%esp), %edx      
    
    movl $0, %eax
    movl $0, cont

    jmp bubble_sortHPF

# CONTROLLA CHI HA SCADENZA MINORE IN CASO DI PRIORITA' UGUALE
OrdinaScad:
    movl %eax, temp
    leal 4(%edx), %edx     
    movl (%edx), %eax   
    cmpl 4(%ebx), %eax 
    leal -4(%edx), %edx          
    movl temp, %eax
    jl scampioHPF                  

    jmp noscambio


# STAMPA PIANIFICAZIONE HPF
Output_hpf:   
    # STAMPA HPF
    movl $4, %eax           
    movl $1, %ebx           
    leal strHpf, %ecx      
    movl strHpf_length, %edx  
    int $0x80

    movl nr_ordini, %edx
    movl $0, cont

    jmp output_id


# OUTPUT

# TRASFORMO VALORE INT ID IN STRING
output_id:
    movl $0, %esi
    movl %esp, %eax
    movl (%eax), %eax 

    cmpl $1, val
    jne next
    leal 8(%eax), %eax
    jmp nextnext
next:                           ##next e nextnext, cambiano l'offset applicato a esp (eax) in base all'algoritmo scelto, eax deve puntare al valore id del ordine a cui corrisponde l'indirizzo 
    leal 12(%eax), %eax
nextnext:
    leal id_pila, %esi  
   
    addl $2, %esi           # faccio puntare ESI alla terza cifra
    movl $10, %ebx          # carisco il divisore in EBX
    movl $3, %ecx             # inizializzo il contatore in ECX

    incl cont 
    movl (%eax), %eax

inizioCiclo:
    div %bl                 # divido per 10
    addb $48, %ah           # trovo il valore numerico in codifica ascii della cifra da inserire, cioè 0(in ascii 48) + AH

    movb %ah, (%esi)        # salva AH nel indirizzo di memoria puntato da ESI. (ricorda il valore di esi è un indirizzo).
    xorb %ah, %ah
    decl %esi
    cmpb $0, %al
    je stampa_id

    loop inizioCiclo 
       
# STAMPO ID
stampa_id: 
    movl $4, %eax
    movl $1, %ebx
    leal id_pila, %ecx
    movl $4, %edx

    int $0x80
 
    movl $0, 2(%esi)
    movl $0, 1(%esi)

    # STAMPO :
    movl $4, %eax
    movl $1, %ebx
    leal duePunti, %ecx
    movl $1, %edx

    int $0x80


calcolo_inizio:
    movl corrente, %eax    
    movl %eax, precedente 

    movl %esp, %eax
    movl (%eax), %eax 

    cmpl $1, val
    jne nextQuattro
    movl (%eax), %edx
    movl %edx, scadenza
    jmp nextnextQuattro

nextQuattro:
    leal 4(%eax), %edx
    movl (%edx), %edx
    movl %edx, scadenza

nextnextQuattro:
    cmpl $1, val
    jne nextDue
    leal 4(%eax), %eax
    jmp nextnextDue

nextDue:
    leal 8(%eax), %eax

nextnextDue:
    movl %eax, %edx
    movl (%edx), %edx
    addl %edx, corrente            

    leal inizio_produz, %esi     
    addl $1, %esi               # faccio puntare ESI alla seconda cifra
    movl $10, %ebx              # carisco il divisore in EBX
    movl $2, %ecx               # inizializzo il contatore in ECXW

    movl precedente, %eax   
    movl corrente, %edx
    
    cmpl %edx, scadenza
    jge ciclo

# TRASFORMA PENALTY DA INT A STRING
calcolo_penalty:
    movl scadenza, %ebx
    subl %ebx, %edx
    
    movl %esp, %eax
    movl (%eax), %eax 

    cmpl $1, val
    jne nextnextTre
    leal -4(%eax), %eax
    jmp nextnextTre 

nextnextTre:
    movl (%eax), %eax

    mull %edx
    
    addl %eax, totPenality
    movl precedente, %eax  
    movl $10, %ebx          # carisco il divisore in EBX
    
ciclo:
    div %bl                 # divido per 10
    addb $48, %ah           # trovo il valore numerico in codifica ascii della cifra da inserire, cioè 0(in ascii 48) + AH

    movb %ah, (%esi)        # salva AH nel indirizzo di memoria puntato da ESI. (ricorda il valore di esi è un indirizzo).
    xorb %ah, %ah
    decl %esi
    cmpb $0, %al
    je stampa_inzio

    loop ciclo    

# STAMPO INIZIO_PRODUZ
stampa_inzio:
    popl %ebx

    # STAMPO INIZIO_PRODUZ
    movl $4, %eax
    movl $1, %ebx
    leal inizio_produz, %ecx
    movl $2, %edx
    int $0x80

    movl $0, 1(%esi)

    # STAMPO NEW LINE
    movl $4, %eax
    movl $1, %ebx
    leal newLine, %ecx
    movl $1, %edx
    int $0x80

    movl cont, %edx
    cmpl %edx, nr_ordini
    je stampaStringConcl

    jmp output_id

# STAMPO STRINGA CONCLUSIONE
stampaStringConcl:
    movl $4, %eax
    movl $1, %ebx
    leal conclusione, %ecx
    movl concl_length, %edx
    int $0x80

    leal conclus_string, %esi     
    addl $2, %esi           # faccio puntare ESI alla terza cifra
    movl $10, %ebx          # carisco il divisore in EBX
    movl $3, %ecx  

    movl corrente, %eax

# CALCOLO CONLUSIONEE
conclus:
    div %bl                 # divido per 10
    addb $48, %ah           # trovo il valore numerico in codifica ascii della cifra da inserire, cioè 0(in ascii 48) + AH
    movb %ah, (%esi)        # salva AH nel indirizzo di memoria puntato da ESI. (ricorda il valore di esi è un indirizzo).
    xorb %ah, %ah
    decl %esi
    cmpb $0, %al
    je stampaConcl

    loop conclus

# STAMPO CONCLUSIONE
stampaConcl:
    movl $4, %eax
    movl $1, %ebx
    leal conclus_string, %ecx
    movl $3, %edx
    int $0x80

# STAMPO STRING PENALTA
stampaStringPenality:

   ##STAMPO NEW LINE
    movl $4, %eax
    movl $1, %ebx
    leal newLine, %ecx
    movl $1, %edx
    int $0x80
    
    ##STAMPO STRINGA PENALITA
    movl $4, %eax
    movl $1, %ebx
    leal penality, %ecx
    movl penality_length, %edx
    int $0x80

    leal penality_string, %esi     
    addl $3, %esi           # faccio puntare ESI alla terza cifra
    movl $10, %ebx          # carisco il divisore in EBX
    movl $4, %ecx  

    movl totPenality, %eax

# CALCOLO PENALITA
calcPenality:
    div %bl                 # divido per 10
    addb $48, %ah           # trovo il valore numerico in codifica ascii della cifra da inserire, cioè 0(in ascii 48) + AH
    movb %ah, (%esi)        # salva AH nel indirizzo di memoria puntato da ESI. (ricorda il valore di esi è un indirizzo).
    xorb %ah, %ah
    decl %esi
    cmpb $0, %al
    je stampaPenality

    loop calcPenality

# STAMPO PENALITA
stampaPenality:
    movl $4, %eax
    movl $1, %ebx
    leal penality_string, %ecx
    movl $4, %edx
    int $0x80   

    movl $0, 1(%esi)
    movl $0, 2(%esi)

# AZZERO
azzeramento:
    decl nr_ordini
    movl $0, cont
    movl $0, totPenality
    movl $0, corrente
    movl $0, precedente

    movl $8, %ecx  

# AZZERA STRINGA ID_PILA (causa interferenze)
azzera_id_pila:
    movl $0, id_pila(%ecx)
    decl %ecx
    cmpl $0, %ecx
    jne azzera_id_pila
    movl lunghezza_nfile, %ebx  
    jmp menu

# ERRORE INSERIMENTO INPUT MENU
err_input_menu:
    movl $4, %eax
    movl $1, %ebx
    leal str_err_input_menu, %ecx
    movl str_err_input_menu_length, %edx
    int $0x80
    jmp fine

# ERRORE VALORI FILE
err_val_file:
    movl $4, %eax
    movl $1, %ebx
    leal str_err_val_file, %ecx
    movl str_err_val_file_length, %edx
    int $0x80
    jmp fine

# FINE
fine:
    movl $1, %eax
    movl $0, %ebx
    int $0x80
