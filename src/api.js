const base=(import.meta.env.VITE_API_URL||'').replace(/\/$/,'');
export async function api(path,options={}) {
  let response;
  try { response=await fetch(base+path,{...options,headers:{'Content-Type':'application/json',Authorization:`Bearer ${sessionStorage.getItem('bank-api-token')||''}`,...options.headers},signal:AbortSignal.timeout(15000)}); }
  catch { throw new Error('Не удалось подключиться к API. Проверьте запуск сервера и VITE_API_URL.'); }
  const data=await response.json().catch(()=>null);
  if(!response.ok)throw new Error(data?.error||`Ошибка API (${response.status})`);
  if(data===null)throw new Error('API вернул неверный ответ. Проверьте адрес сервера.');
  return data;
}
