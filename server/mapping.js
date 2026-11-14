const status={pending:'В обработке',completed:'Выполнено',failed:'Отклонено',cancelled:'Отменено'};
export const mappings={
 accounts:{account_type:{checking:'Текущий',savings:'Сберегательный',business:'Бизнес'},status:{active:'Активен',frozen:'Заблокирован',closed:'Закрыт'}},
 transactions:{transaction_type:{transfer:'Перевод',deposit:'Пополнение',withdrawal:'Снятие',fee:'Комиссия'},status},
 transfers:{transfer_type:{internal:'Внутренний',interbank:'Межбанковский',crypto_withdrawal:'Вывод криптовалюты'},status},
 loans:{status:{pending:'На рассмотрении',approved:'Одобрен',active:'Активен',paid:'Погашен',rejected:'Отклонён'}},
 bank_shareholders:{holder_type:{individual:'Физическое лицо',company:'Компания',state:'Государство'}}
};
export function translate(table,row,toDatabase=false){return Object.fromEntries(Object.entries(row).map(([key,value])=>{const map=mappings[table]?.[key];return [key,map?(toDatabase?Object.entries(map).find(([,label])=>label===value)?.[0]??value:map[value]??value):value]}));}
