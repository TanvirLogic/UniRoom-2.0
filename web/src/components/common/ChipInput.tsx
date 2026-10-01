import React, { useState } from 'react';
import { X } from 'lucide-react';

interface ChipInputProps {
  chips: string[];
  onChange: (chips: string[]) => void;
  placeholder?: string;
  label?: string;
}

export const ChipInput: React.FC<ChipInputProps> = ({
  chips,
  onChange,
  placeholder = 'Type section (e.g. A) and press Enter...',
  label,
}) => {
  const [inputVal, setInputVal] = useState('');

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      addChip();
    } else if (e.key === 'Backspace' && !inputVal && chips.length > 0) {
      removeChip(chips.length - 1);
    }
  };

  const addChip = () => {
    const trimmed = inputVal.trim().toUpperCase();
    if (trimmed && !chips.includes(trimmed)) {
      onChange([...chips, trimmed].sort());
      setInputVal('');
    }
  };

  const removeChip = (indexToRemove: number) => {
    onChange(chips.filter((_, idx) => idx !== indexToRemove));
  };

  return (
    <div className="w-full">
      {label && <label className="block text-xs font-medium text-slate-300 mb-1.5">{label}</label>}
      <div className="flex flex-wrap items-center gap-1.5 p-2 bg-slate-950/60 border border-slate-800 rounded-xl focus-within:border-emerald-500 focus-within:ring-1 focus-within:ring-emerald-500 transition-all min-h-[44px]">
        {chips.map((chip, idx) => (
          <span
            key={idx}
            className="inline-flex items-center gap-1 px-2.5 py-0.5 bg-emerald-500/10 text-emerald-300 border border-emerald-500/20 text-xs font-semibold rounded-lg"
          >
            {chip}
            <button
              type="button"
              onClick={() => removeChip(idx)}
              className="text-emerald-400 hover:text-emerald-100 transition-colors"
            >
              <X className="w-3 h-3" />
            </button>
          </span>
        ))}
        <input
          type="text"
          value={inputVal}
          onChange={(e) => setInputVal(e.target.value)}
          onKeyDown={handleKeyDown}
          onBlur={addChip}
          placeholder={chips.length === 0 ? placeholder : ''}
          className="flex-1 bg-transparent border-none text-xs text-slate-100 placeholder-slate-500 focus:outline-none min-w-[120px] px-1 py-1"
        />
      </div>
      <p className="mt-1 text-[11px] text-slate-500">Press Enter or Comma to add section tags</p>
    </div>
  );
};
