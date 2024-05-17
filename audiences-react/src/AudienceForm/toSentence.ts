import join from "lodash/join";

export function toSentence(names: string[]) {
  if (names.length == 1) {
    return names;
  } else if (names.length == 2) {
    return join(names, " and ");
  } else {
    const all = [...names]
    const lastOne = all.pop();

    return `${join(all, ", ")}, and ${lastOne}`;
  }
}
