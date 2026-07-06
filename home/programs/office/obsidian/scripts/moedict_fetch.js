/**
 * Templater user script: Fetch and cache moedict.tw data
 * Returns an object with { meaning, zhuyin } - call once per template
 * Usage:
 *   <%* const moe = await tp.user.moedict_fetch(tp.file.title) %>
 *   Then use: <% moe.meaning %> and <% moe.zhuyin %>
 */
async function moedict_fetch(word) {
  const result = {
    meaning: "TODO add meaning",
    zhuyin: "TODO add zhuyin",
  };

  if (!word || word.trim() === "") {
    return result;
  }

  try {
    const response = await fetch(
      `https://www.moedict.tw/a/${encodeURIComponent(word)}.json`,
    );

    if (!response.ok) {
      return result;
    }

    const data = await response.json();

    // Extract zhuyin from first heteronym
    if (data.h?.length > 0 && data.h[0].b) {
      result.zhuyin = data.h[0].b.replace(/\s+/g, " ").trim();
    }

    // Extract English meaning
    if (data.translation?.English?.length > 0) {
      const meanings = data.translation.English.filter(
        (m) => !m.startsWith("CL:"),
      ).join("; ");
      if (meanings) {
        result.meaning = meanings;
      }
    } else if (data.English) {
      result.meaning = data.English;
    }

    return result;
  } catch (error) {
    console.error("moedict_fetch error:", error);
    return result;
  }
}

module.exports = moedict_fetch;
