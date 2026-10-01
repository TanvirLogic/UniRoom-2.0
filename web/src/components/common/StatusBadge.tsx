import React from 'react';
import { RoomStatusType } from '../../api/rooms.api';

interface StatusBadgeProps {
  status: RoomStatusType;
  showDot?: boolean;
  size?: 'sm' | 'md';
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, showDot = true, size = 'md' }) => {
  const configs: Record<
    RoomStatusType,
    { label: string; bg: string; text: string; dot: string; border: string }
  > = {
    AVAILABLE: {
      label: 'Available',
      bg: 'bg-emerald-950/60',
      text: 'text-emerald-400',
      dot: 'bg-emerald-400',
      border: 'border-emerald-800/40',
    },
    RUNNING_CLASS: {
      label: 'Class Running',
      bg: 'bg-amber-950/60',
      text: 'text-amber-400',
      dot: 'bg-amber-400',
      border: 'border-amber-800/40',
    },
    RESERVED: {
      label: 'Reserved',
      bg: 'bg-blue-950/60',
      text: 'text-blue-400',
      dot: 'bg-blue-400',
      border: 'border-blue-800/40',
    },
    MAINTENANCE: {
      label: 'Maintenance',
      bg: 'bg-rose-950/60',
      text: 'text-rose-400',
      dot: 'bg-rose-400',
      border: 'border-rose-800/40',
    },
  };

  const cfg = configs[status] || configs.AVAILABLE;
  const padding = size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-xs';

  return (
    <span
      className={`inline-flex items-center gap-1.5 font-medium rounded-full border ${cfg.bg} ${cfg.text} ${cfg.border} ${padding}`}
    >
      {showDot && (
        <span
          className={`h-1.5 w-1.5 rounded-full ${cfg.dot} ${
            status === 'RUNNING_CLASS' ? 'animate-pulse' : ''
          }`}
        />
      )}
      {cfg.label}
    </span>
  );
};
