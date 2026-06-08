export async function GET(request) {
  try {
    const { searchParams } = new URL(request.url);
    const destination = searchParams.get("destination");

    if (!destination) {
      return Response.json(
        { error: "Destination parameter is required" },
        { status: 400 },
      );
    }

    // Search for comprehensive destination information
    const queries = [
      `${destination} best attractions and things to do`,
      `${destination} travel guide tips`,
      `${destination} weather and best time to visit`,
      `${destination} local food and restaurants`,
    ];

    const searchPromises = queries.map(async (query) => {
      try {
        const response = await fetch(
          `/integrations/google-search/search?q=${encodeURIComponent(query)}`,
          { method: "GET" },
        );
        if (!response.ok) return null;
        return await response.json();
      } catch (err) {
        console.error(`Error searching ${query}:`, err);
        return null;
      }
    });

    const results = await Promise.all(searchPromises);

    // Compile information
    const destinationDetails = {
      name: destination,
      attractions: [],
      travelTips: [],
      weather: [],
      dining: [],
      sources: [],
    };

    // Parse results
    results.forEach((result, index) => {
      if (!result?.items) return;

      const category = ["attractions", "travelTips", "weather", "dining"][
        index
      ];

      result.items.slice(0, 3).forEach((item) => {
        destinationDetails[category].push({
          title: item.title,
          snippet: item.snippet,
          link: item.link,
        });

        if (!destinationDetails.sources.includes(item.link)) {
          destinationDetails.sources.push(item.link);
        }
      });
    });

    // Get images
    try {
      const imageResponse = await fetch(
        `/integrations/google-search/search?q=${encodeURIComponent(destination + " travel photography")}`,
        { method: "GET" },
      );

      if (imageResponse.ok) {
        const imageResults = await imageResponse.json();
        if (imageResults?.items) {
          destinationDetails.images = imageResults.items
            .filter((item) => item.pagemap?.cse_image?.[0]?.src)
            .slice(0, 5)
            .map((item) => ({
              url: item.pagemap.cse_image[0].src,
              thumbnail: item.pagemap.cse_image[0].src,
              title: item.title,
            }));
        }
      }
    } catch (error) {
      console.error("Error fetching images:", error);
    }

    return Response.json({ details: destinationDetails });
  } catch (error) {
    console.error("Error fetching destination details:", error);
    return Response.json(
      { error: "Failed to fetch destination details", details: error.message },
      { status: 500 },
    );
  }
}
