export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const query = searchParams.get("query");

    if (!query) {
      return Response.json(
        { error: "Query parameter is required" },
        { status: 400 },
      );
    }

    // Search for destination information using Google Search with more specific queries
    const searchQuery = `${query} travel guide tourist attractions top places to visit things to do`;
    const searchResponse = await fetch(
      `/integrations/google-search/search?q=${encodeURIComponent(searchQuery)}`,
      { method: "GET" },
    );

    if (!searchResponse.ok) {
      throw new Error("Search failed");
    }

    const searchResults = await searchResponse.json();

    if (!searchResults?.items || searchResults.items.length === 0) {
      return Response.json({
        destination: null,
        message: "No results found",
      });
    }

    // Get the most relevant results
    const topResults = searchResults.items.slice(0, 5);

    // Extract key information
    const destinationInfo = {
      name: query,
      description: topResults[0].snippet || "",
      source: topResults[0].link,
      title: topResults[0].title,
      attractions: [],
      relatedResults: topResults.slice(1, 4).map((result) => ({
        title: result.title,
        snippet: result.snippet,
        link: result.link,
      })),
    };

    // Try to extract attraction names from snippets
    topResults.forEach((result) => {
      if (result.snippet) {
        // Look for common patterns like "Top 10", "Best places", etc.
        const snippet = result.snippet.toLowerCase();
        if (
          snippet.includes("attractions") ||
          snippet.includes("places to visit") ||
          snippet.includes("things to do") ||
          snippet.includes("must see")
        ) {
          destinationInfo.attractions.push({
            source: result.title,
            description: result.snippet,
            link: result.link,
          });
        }
      }
    });

    // Search specifically for top attractions
    try {
      const attractionsQuery = `${query} top 10 tourist attractions landmarks`;
      const attractionsResponse = await fetch(
        `/integrations/google-search/search?q=${encodeURIComponent(attractionsQuery)}`,
        { method: "GET" },
      );

      if (attractionsResponse.ok) {
        const attractionsResults = await attractionsResponse.json();
        if (attractionsResults?.items) {
          destinationInfo.topAttractions = attractionsResults.items
            .slice(0, 3)
            .map((item) => ({
              title: item.title,
              snippet: item.snippet,
              link: item.link,
            }));
        }
      }
    } catch (error) {
      console.error("Error fetching top attractions:", error);
    }

    // Search for images with better quality
    try {
      const imageQuery = `${query} travel destination tourism photography landmarks`;
      const imageSearchResponse = await fetch(
        `/integrations/google-search/search?q=${encodeURIComponent(imageQuery)}`,
        { method: "GET" },
      );

      if (imageSearchResponse.ok) {
        const imageResults = await imageSearchResponse.json();
        if (imageResults?.items) {
          // Extract images from page metadata if available
          destinationInfo.images = imageResults.items
            .filter((item) => item.pagemap?.cse_image?.[0]?.src)
            .slice(0, 8)
            .map((item) => ({
              url: item.pagemap.cse_image[0].src,
              thumbnail: item.pagemap.cse_image[0].src,
              title: item.title,
              source: item.link,
            }));
        }
      }
    } catch (error) {
      console.error("Error fetching images:", error);
    }

    return Response.json({ destination: destinationInfo });
  } catch (error) {
    console.error("Error searching destination:", error);
    return Response.json(
      { error: "Failed to search destination", details: error.message },
      { status: 500 },
    );
  }
}
