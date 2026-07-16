const identity = <T,>(value: T) => value;
export const view = <Box value={identity<number>(1)} />;
