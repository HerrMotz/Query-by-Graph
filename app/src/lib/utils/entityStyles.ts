export function getEntityStyles(isVariable: boolean, isSelected: boolean, isLiteral?: boolean) {
  if (isLiteral) {
    return {
      border: 'ring-amber-600',
      bg: 'bg-amber-100',
      nodeBg: 'bg-amber-500',
      nodeHoverBg: 'hover:bg-amber-600',
      connection: 'stroke-amber-600',
      connectionHover: 'hover:stroke-amber-400'
    };
  }
  if (isVariable) {
    if (isSelected) {
      return {
        border: 'ring-green-600',
        bg: 'bg-green-100',
        nodeBg: 'bg-green-600',
        nodeHoverBg: 'hover:bg-green-700',
        connection: 'stroke-green-600',
        connectionHover: 'hover:stroke-green-400'
      };
    } else {
      return {
        border: 'ring-violet-600',
        bg: 'bg-violet-100',
        nodeBg: 'bg-violet-400',
        nodeHoverBg: 'hover:bg-violet-500',
        connection: 'stroke-violet-600',
        connectionHover: 'hover:stroke-violet-400'
      };
    }
  } else {
    return {
      border: 'ring-indigo-500',
      bg: 'bg-indigo-50', // light indigo background
      nodeBg: 'bg-indigo-300',
      nodeHoverBg: 'hover:bg-indigo-400',
      connection: 'stroke-indigo-600',
      connectionHover: 'hover:stroke-indigo-400'
    };
  }
}
