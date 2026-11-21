// Anemone Mine dig planner, pure for `node --test`. Mafia's mineState3 is 36 chars, index
// (row-1)*6 + (col-1), row 1 the top and row 6 the open front; 'o' open, '*' promising, 'X'
// rock. KoL's square number is row*8 + col. Without Object Detection only promising squares
// next to open space twinkle; with it the whole wall does (wiki Mining).
//
// Where the teflon is, from every square this account dug (52 session logs, 2026-10-17):
//   row 1: 12 teflon / 32 dug   row 2: 60 / 176 (94% some ore)   row 3: 7 / 57
//   row 4: 0 / 36 (17 cave-ins)  rows 5-6: no ore at all
// So the plan walks the fewest digs to a twinkle in rows 1-2; with none in view it runs the
// blind shaft up column 3 to row 2 and along it (the pre-detection order, which reaches the
// ore row on the fifth pick), and only then chases row-3 twinkles. Rows 4-6 are never dug
// for their own sake. A wall is never abandoned (user rule 2026-10-17).

export type Square = [col: number, row: number];

export type DigPlan =
  | { action: "dig"; square: Square; cost: number; target: Square }
  | { action: "none" };

const COLS = 6;
const ROWS = 6;
const OPEN = "o";
const SPARKLE = "*";
/** Rows worth walking to: 1-2 first; after the shaft, row 3, then row 4 (every mine holds one
 *  vein of four per ore somewhere in rows 1-4, so a dug-out rows 1-3 leaves teflon in row 4). */
const ORE_ROWS = 2;
const FALLBACK_ROWS = [3, 4];

/** The blind shaft: up column 3 to the ore row, then along row 2, then row 1. */
export const SHAFT: Square[] = [
  [3, 6],
  [3, 5],
  [3, 4],
  [3, 3],
  [3, 2],
  [2, 2],
  [4, 2],
  [5, 2],
  [1, 2],
  [6, 2],
  [3, 1],
  [2, 1],
  [4, 1],
  [5, 1],
  [1, 1],
  [6, 1],
];

export function indexOf([col, row]: Square): number {
  return (row - 1) * COLS + (col - 1);
}

export function squareOf(index: number): Square {
  return [(index % COLS) + 1, Math.floor(index / COLS) + 1];
}

export function whichOf([col, row]: Square): number {
  return row * 8 + col;
}

/** Squares mafia's mineLayout<n> records as velcro or vinyl ore (already dug, wrong vein). */
export function parseBadOre(layout: string): Square[] {
  const squares: Square[] = [];
  const re = /#(\d+)<img src="[^"]*\/(velcroore|vinylore)\.gif"/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(layout)) !== null) {
    const which = parseInt(m[1], 10);
    squares.push([which % 8, Math.floor(which / 8)]);
  }
  return squares;
}

function neighbors(index: number): number[] {
  const [col, row] = squareOf(index);
  const out: number[] = [];
  if (col > 1) out.push(index - 1);
  if (col < COLS) out.push(index + 1);
  if (row > 1) out.push(index - COLS);
  if (row < ROWS) out.push(index + COLS);
  return out;
}

type Paths = {
  /** Digs to open each square, itself included. */
  dist: number[];
  /** Twinkles dug on the way, the target included (a free extra sample each). */
  sparkles: number[];
  /** The exposed square the path starts from. */
  first: number[];
};

/** Fewest digs to each square from the open front and any open square; among equal digs the
 *  path through more twinkles wins. */
function digPaths(state: string): Paths {
  const dist: number[] = Array(state.length).fill(Infinity);
  const sparkles: number[] = Array(state.length).fill(0);
  const first: number[] = Array(state.length).fill(-1);
  const better = (i: number, d: number, s: number): boolean =>
    d < dist[i] || (d === dist[i] && s > sparkles[i]);
  const pending = new Set<number>();
  for (let i = 0; i < state.length; i++) {
    if (state[i] === OPEN) continue;
    const [, row] = squareOf(i);
    const exposed = row === ROWS || neighbors(i).some((n) => state[n] === OPEN);
    if (!exposed) continue;
    dist[i] = 1;
    sparkles[i] = state[i] === SPARKLE ? 1 : 0;
    first[i] = i;
    pending.add(i);
  }
  // Dijkstra on a 36-square grid: pop the best pending square each round.
  while (pending.size > 0) {
    let i = -1;
    for (const p of pending) {
      if (i === -1 || dist[p] < dist[i] || (dist[p] === dist[i] && sparkles[p] > sparkles[i])) {
        i = p;
      }
    }
    pending.delete(i);
    for (const n of neighbors(i)) {
      if (state[n] === OPEN) continue;
      const d = dist[i] + 1;
      const s = sparkles[i] + (state[n] === SPARKLE ? 1 : 0);
      if (better(n, d, s)) {
        dist[n] = d;
        sparkles[n] = s;
        first[n] = first[i];
        pending.add(n);
      }
    }
  }
  return { dist, sparkles, first };
}

function clusterSize(state: string, start: number): number {
  const seen = new Set<number>([start]);
  const stack = [start];
  while (stack.length > 0) {
    const i = stack.pop() as number;
    for (const n of neighbors(i)) {
      if (state[n] === SPARKLE && !seen.has(n)) {
        seen.add(n);
        stack.push(n);
      }
    }
  }
  return seen.size;
}

function adjacentToBadOre(index: number, badOre: Set<number>): boolean {
  return neighbors(index).some((n) => badOre.has(n));
}

type Target = { index: number; cost: number; sparkles: number; size: number };

/** The best twinkle whose row is in [minRow, maxRow]: fewest digs, then more twinkles on the
 *  way, then the bigger cluster. Twinkles next to a revealed wrong ore wait for a second pass. */
function bestTarget(
  state: string,
  badOre: Set<number>,
  paths: Paths,
  minRow: number,
  maxRow: number,
): Target | undefined {
  for (let pass = 0; pass < 2; pass++) {
    let best: Target | undefined;
    for (let i = 0; i < state.length; i++) {
      if (state[i] !== SPARKLE || paths.dist[i] === Infinity) continue;
      const [, row] = squareOf(i);
      if (row < minRow || row > maxRow) continue;
      if (pass === 0 && adjacentToBadOre(i, badOre)) continue;
      const candidate = {
        index: i,
        cost: paths.dist[i],
        sparkles: paths.sparkles[i],
        size: clusterSize(state, i),
      };
      if (
        best === undefined ||
        candidate.cost < best.cost ||
        (candidate.cost === best.cost && candidate.sparkles > best.sparkles) ||
        (candidate.cost === best.cost &&
          candidate.sparkles === best.sparkles &&
          candidate.size > best.size)
      ) {
        best = candidate;
      }
    }
    if (best) return best;
  }
  return undefined;
}

function digToward(paths: Paths, target: Target): DigPlan {
  return {
    action: "dig",
    square: squareOf(paths.first[target.index]),
    cost: target.cost,
    target: squareOf(target.index),
  };
}

/**
 * The next square to dig: a visible twinkle in rows 1-2 by the fewest digs (every twinkle is
 * visible under Object Detection, only the exposed ones without), else the blind shaft, else a
 * row-3 twinkle, else a row-4 twinkle, else nothing. Twinkles beside a revealed wrong ore are
 * taken after the others but before plain rock: on this account's walls 56 of 128 adjacent
 * dug-ore pairs were different veins (veins touch), so "it's definitely the same vein" is not
 * true here.
 */
export function planDig(state: string, badOre: Square[]): DigPlan {
  if (state.length !== COLS * ROWS) return { action: "none" };
  const bad = new Set(badOre.map(indexOf));
  const paths = digPaths(state);

  const ore = bestTarget(state, bad, paths, 1, ORE_ROWS);
  if (ore) return digToward(paths, ore);

  const shaft = SHAFT.find((sq) => state[indexOf(sq)] !== OPEN);
  if (shaft) return { action: "dig", square: shaft, cost: 1, target: shaft };

  for (const row of FALLBACK_ROWS) {
    const fallback = bestTarget(state, bad, paths, row, row);
    if (fallback) return digToward(paths, fallback);
  }

  return { action: "none" };
}
