// Anemone Mine vein solver, pure for `node --test`. The wiki (Anemone Mine (Mining)), the
// community spading (Discord 2026-08-24, brain fact anemone-mine-veins) and this account's
// logs agree on the generator: a 6x6 wall holds 12 ore (one contiguous vein of four per ore,
// snaking allowed, veins may touch, rows 1-4 only and row 4 rarely), 3 dense meat stacks, 4
// cave-ins, 1 marine aquamarine (a plain square unless Grandpa was asked about the mine) and
// 16 Rocky Walls: so 20 promising squares, or 19 without the aquamarine, i.e. exactly 8 or 7
// duds among the 24 non-ore squares, and on the logged walls those duds land at about one
// per three non-ore squares in every row, which is what a uniform spread of 8 over 24 gives.
// That is small enough to solve exactly: enumerate every 4-connected placement over the 24
// cells of rows 1-4, weight each (teflon, velcro, vinyl) triple of disjoint placements by the
// number of ways the duds can fill the non-ore squares consistently with every twinkle and
// plain square seen, and read off the probability that each square is teflon. Digging is
// greedy on that probability with a discounted look past the square at what it would expose.
//
// Cell indexing follows lib/mineplan: index (row-1)*6 + (col-1), row 1 the top; only rows 1-4
// hold ore, so a vein is a 24-bit mask and JavaScript's 32-bit bitwise ops are enough.
import { Square, squareOf } from "./mineplan";

export const COLS = 6;
export const ROWS = 6;
export const CELLS = COLS * ROWS; // 36
export const ORE_ROWS = 4;
export const ORE_CELLS = COLS * ORE_ROWS; // 24
export const ORE_COUNT = 12;

export type CellStatus =
  | "unknown" // undug and not exposed (no detection): could be anything
  | "twinkle" // undug, promising: ore (rows 1-4) or a dud
  | "rock" // undug and seen plain, or dug and found nothing: no ore, no dud
  | "dud" // dug: cave-in, meat stack, aquamarine
  | "teflon"
  | "velcro"
  | "vinyl";

/** One status per cell of the whole wall (36); rows 5-6 never hold ore. */
export type Observation = CellStatus[];

export type SolverParams = {
  /** Prior weight per vein cell in row 4 (ore is rare there: 5 of 82 dug squares). */
  row4Weight: number;
  /** Dud twinkles per wall and their prior weights: 8 with the aquamarine, 7 without. */
  duds: { count: number; weight: number }[];
  /** Discount per extra dig when scoring a square by what it leads to. */
  beta: number;
};

export const DEFAULT_PARAMS: SolverParams = {
  row4Weight: 0.2,
  duds: [
    { count: 8, weight: 0.5 },
    { count: 7, weight: 0.5 },
  ],
  beta: 0.5,
};

function neighborsOf(index: number, cols: number, rows: number): number[] {
  const col = index % cols;
  const row = Math.floor(index / cols);
  const out: number[] = [];
  if (col > 0) out.push(index - 1);
  if (col < cols - 1) out.push(index + 1);
  if (row > 0) out.push(index - cols);
  if (row < rows - 1) out.push(index + cols);
  return out;
}

function connected(cells: number[]): boolean {
  const set = new Set(cells);
  const seen = new Set<number>([cells[0]]);
  const stack = [cells[0]];
  while (stack.length > 0) {
    const i = stack.pop() as number;
    for (const n of neighborsOf(i, COLS, ORE_ROWS)) {
      if (set.has(n) && !seen.has(n)) {
        seen.add(n);
        stack.push(n);
      }
    }
  }
  return seen.size === cells.length;
}

let placementCache: number[] | undefined;

/** Every 4-connected set of four cells in rows 1-4, as 24-bit masks. */
export function veinPlacements(): number[] {
  if (placementCache) return placementCache;
  const out: number[] = [];
  for (let a = 0; a < ORE_CELLS; a++) {
    for (let b = a + 1; b < ORE_CELLS; b++) {
      for (let c = b + 1; c < ORE_CELLS; c++) {
        for (let d = c + 1; d < ORE_CELLS; d++) {
          if (connected([a, b, c, d])) out.push((1 << a) | (1 << b) | (1 << c) | (1 << d));
        }
      }
    }
  }
  placementCache = out;
  return out;
}

function popcount(mask: number): number {
  let n = 0;
  let m = mask;
  while (m !== 0) {
    m &= m - 1;
    n++;
  }
  return n;
}

const ROW4_MASK = (() => {
  let mask = 0;
  for (let i = 3 * COLS; i < ORE_CELLS; i++) mask |= 1 << i;
  return mask;
})();

/** C(n, k), 0 outside the triangle. */
export function choose(n: number, k: number): number {
  if (k < 0 || n < 0 || k > n) return 0;
  let r = 1;
  for (let i = 1; i <= k; i++) r = (r * (n - k + i)) / i;
  return Math.round(r);
}

/** mafia's mineLayout image names -> what a dug square held. */
export function contentStatus(image: string): CellStatus {
  if (image.includes("teflon")) return "teflon";
  if (image.includes("velcro")) return "velcro";
  if (image.includes("vinyl")) return "vinyl";
  return "dud";
}

/**
 * The wall as the solver sees it: `state` is mafia's mineState3, `layout` its mineLayout3
 * (what each dug square held), `detection` whether every twinkle is visible.
 */
export function observe(state: string, layout: string, detection: boolean): Observation {
  const dug = new Map<number, CellStatus>();
  const re = /#(\d+)<img src="[^"]*\/([a-z0-9]+)\.gif"/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(layout)) !== null) {
    const which = parseInt(m[1], 10);
    const col = which % 8;
    const row = Math.floor(which / 8);
    if (row >= 1 && row <= ROWS && col >= 1 && col <= COLS) {
      dug.set((row - 1) * COLS + (col - 1), contentStatus(m[2]));
    }
  }
  const obs: Observation = [];
  for (let i = 0; i < CELLS; i++) {
    const ch = state.charAt(i);
    if (ch === "o") {
      obs.push(dug.get(i) ?? "rock");
    } else if (ch === "*") {
      obs.push("twinkle");
    } else {
      const row = Math.floor(i / COLS);
      const exposed =
        detection ||
        row === ROWS - 1 ||
        neighborsOf(i, COLS, ROWS).some((n) => state.charAt(n) === "o");
      obs.push(exposed ? "rock" : "unknown");
    }
  }
  return obs;
}

type Masks = {
  /** Rows 1-4 twinkles still undug (ore or dud). */
  twinkle: number;
  /** Rows 1-4 cells no ore may sit on: seen plain, dug empty, or dug dud. */
  blocked: number;
  ore: Record<"teflon" | "velcro" | "vinyl", number>;
  unknown: number;
  /** Over the whole wall: squares known to be duds (undug twinkles count as duds unless
   *  ore covers them) and squares known to be plain. */
  knownDudOrTwinkle: number;
  knownPlain: number;
};

function masksOf(obs: Observation): Masks {
  const masks: Masks = {
    twinkle: 0,
    blocked: 0,
    ore: { teflon: 0, velcro: 0, vinyl: 0 },
    unknown: 0,
    knownDudOrTwinkle: 0,
    knownPlain: 0,
  };
  obs.forEach((status, i) => {
    const inOreRows = i < ORE_CELLS;
    const bit = inOreRows ? 1 << i : 0;
    switch (status) {
      case "twinkle":
        masks.twinkle |= bit;
        masks.knownDudOrTwinkle++;
        break;
      case "dud":
        masks.blocked |= bit;
        masks.knownDudOrTwinkle++;
        break;
      case "rock":
        masks.blocked |= bit;
        masks.knownPlain++;
        break;
      case "unknown":
        masks.unknown |= bit;
        break;
      default:
        if (inOreRows) masks.ore[status] |= bit;
    }
  });
  return masks;
}

type Weighted = { mask: number; weight: number; covered: number };

/** Placements of one ore consistent with the wall, with their row prior and how many of the
 *  visible rows-1-4 twinkles they account for. */
function consistentPlacements(
  ore: "teflon" | "velcro" | "vinyl",
  masks: Masks,
  params: SolverParams,
): Weighted[] {
  const must = masks.ore[ore];
  const forbidden =
    masks.blocked |
    (ore === "teflon" ? 0 : masks.ore.teflon) |
    (ore === "velcro" ? 0 : masks.ore.velcro) |
    (ore === "vinyl" ? 0 : masks.ore.vinyl);
  // Without detection an ore cell may be unknown; with it (no unknown cells) it must twinkle
  // or already be dug as this ore.
  const allowed = masks.twinkle | masks.unknown | must;
  const out: Weighted[] = [];
  for (const mask of veinPlacements()) {
    if ((mask & must) !== must) continue;
    if ((mask & forbidden) !== 0) continue;
    if ((mask & ~allowed) !== 0) continue;
    out.push({
      mask,
      weight: Math.pow(params.row4Weight, popcount(mask & ROW4_MASK)),
      covered: popcount(mask & masks.twinkle),
    });
  }
  return out;
}

/**
 * Ways the duds can sit given a triple that covers `covered` of the visible twinkles: the
 * other known twinkles (and dug duds) are duds, the known plain squares are not, and the rest
 * of the duds go anywhere among the remaining non-ore squares.
 */
function dudWays(masks: Masks, covered: number, params: SolverParams): number {
  const knownDuds = masks.knownDudOrTwinkle - covered;
  const free = CELLS - ORE_COUNT - knownDuds - masks.knownPlain;
  let ways = 0;
  for (const { count, weight } of params.duds) {
    ways += weight * choose(free, count - knownDuds);
  }
  return ways;
}

export type Posterior = {
  /** P(teflon) per cell of rows 1-4. */
  teflon: number[];
  /** Weighted count of consistent (teflon, velcro, vinyl) triples; 0 means the model is broken. */
  mass: number;
  /** Consistent placements per ore, before the disjointness join. */
  counts: { teflon: number; velcro: number; vinyl: number };
};

const MAX_COVERED = 4;

/** Exact marginals over the three disjoint veins. */
export function posterior(obs: Observation, params: SolverParams = DEFAULT_PARAMS): Posterior {
  const masks = masksOf(obs);
  const T = consistentPlacements("teflon", masks, params);
  const V = consistentPlacements("velcro", masks, params);
  const W = consistentPlacements("vinyl", masks, params);
  const counts = { teflon: T.length, velcro: V.length, vinyl: W.length };
  const perCell: number[] = Array(ORE_CELLS).fill(0);
  let mass = 0;
  // The dud factor depends only on how many visible twinkles the whole triple covers, so the
  // vinyl inner sum is kept per cover count, memoised by the (teflon | velcro) union.
  const vinylSums = new Map<number, number[]>();
  const vinylByCover = (union: number): number[] => {
    const cached = vinylSums.get(union);
    if (cached !== undefined) return cached;
    const sums: number[] = Array(MAX_COVERED + 1).fill(0);
    for (const w of W) if ((w.mask & union) === 0) sums[w.covered] += w.weight;
    vinylSums.set(union, sums);
    return sums;
  };
  const ways: number[] = [];
  for (let c = 0; c <= 3 * MAX_COVERED; c++) ways.push(dudWays(masks, c, params));
  for (const t of T) {
    let rest = 0;
    for (const v of V) {
      if ((v.mask & t.mask) !== 0) continue;
      const sums = vinylByCover(t.mask | v.mask);
      let inner = 0;
      for (let cw = 0; cw <= MAX_COVERED; cw++) {
        if (sums[cw] === 0) continue;
        inner += sums[cw] * ways[t.covered + v.covered + cw];
      }
      rest += v.weight * inner;
    }
    if (rest === 0) continue;
    const weight = t.weight * rest;
    mass += weight;
    for (let i = 0; i < ORE_CELLS; i++) if ((t.mask & (1 << i)) !== 0) perCell[i] += weight;
  }
  const teflon = mass > 0 ? perCell.map((w) => w / mass) : perCell;
  return { teflon, mass, counts };
}

export type SolvedDig = {
  square: Square;
  /** P(teflon) at that square. */
  p: number;
  /** The look-ahead score the square was chosen on. */
  score: number;
};

/**
 * The exposed undug square to dig: greedy on P(teflon), with every other cell's teflon
 * probability added at beta^(extra digs to reach it through this square). Returns undefined
 * when no placement fits the wall (the model is wrong for it) so the caller can fall back.
 */
export function solveDig(
  state: string,
  layout: string,
  detection: boolean,
  params: SolverParams = DEFAULT_PARAMS,
): SolvedDig | undefined {
  if (state.length !== CELLS) return undefined;
  const post = posterior(observe(state, layout, detection), params);
  if (post.mass === 0) return undefined;
  const open = (i: number): boolean => state.charAt(i) === "o";
  let best: SolvedDig | undefined;
  for (let d = 0; d < CELLS; d++) {
    if (open(d)) continue;
    const row = Math.floor(d / COLS);
    const exposed = row === ROWS - 1 || neighborsOf(d, COLS, ROWS).some(open);
    if (!exposed) continue;
    // BFS through undug cells from d: digs needed to open each cell via d.
    const digs: number[] = Array(CELLS).fill(Infinity);
    digs[d] = 1;
    const queue = [d];
    while (queue.length > 0) {
      const i = queue.shift() as number;
      for (const n of neighborsOf(i, COLS, ROWS)) {
        if (open(n) || digs[n] !== Infinity) continue;
        digs[n] = digs[i] + 1;
        queue.push(n);
      }
    }
    let score = 0;
    for (let s = 0; s < ORE_CELLS; s++) {
      if (digs[s] === Infinity) continue;
      score += post.teflon[s] * Math.pow(params.beta, digs[s] - 1);
    }
    const p = d < ORE_CELLS ? post.teflon[d] : 0;
    if (best === undefined || score > best.score || (score === best.score && p > best.p)) {
      best = { square: squareOf(d), p, score };
    }
  }
  return best;
}
