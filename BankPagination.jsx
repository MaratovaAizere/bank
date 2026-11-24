import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

const SIZES = [10, 25, 50, 100];

/** Shared, client-side page controls for Northstar Bank tables. */
export default function BankPagination({ total = 0, page = 1, pageSize = 25, onPageChange, onPageSizeChange }) {
  const safeSize = SIZES.includes(Number(pageSize)) ? Number(pageSize) : 25;
  const totalPages = Math.max(1, Math.ceil(total / safeSize));
  const current = Math.max(1, Math.min(Number(page) || 1, totalPages));
  const first = total ? (current - 1) * safeSize + 1 : 0;
  const last = Math.min(current * safeSize, total);

  return (
    <div className="table-footer bank-pagination">
      <div className="table-footer-left">
        <span>Показано {first}–{last} из {total}</span>
        <label className="page-size-control">
          На странице:
          <select aria-label="Количество записей на странице" value={safeSize}
            onChange={e => onPageSizeChange(Number(e.target.value))}>
            {SIZES.map(size => <option key={size} value={size}>{size}</option>)}
          </select>
        </label>
      </div>
      <div className="table-footer-navigation">
        <button type="button" disabled={current === 1}
          aria-label="Предыдущая страница" onClick={() => onPageChange(current - 1)}>
          <ChevronLeft size={18} />
        </button>
        <label className="page-jump page-picker">
          Страница
          <select aria-label="Выбрать страницу" value={current}
            onChange={e => onPageChange(Number(e.target.value))}>
            {Array.from({ length: totalPages }, (_, i) => (
              <option key={i + 1} value={i + 1}>{i + 1}</option>
            ))}
          </select>
        </label>
        <span>из {totalPages}</span>
        <button type="button" disabled={current === totalPages}
          aria-label="Следующая страница" onClick={() => onPageChange(current + 1)}>
          <ChevronRight size={18} />
        </button>
      </div>
    </div>
  );
}
