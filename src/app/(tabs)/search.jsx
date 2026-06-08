import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Dimensions,
  ActivityIndicator,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import { ArrowLeft, Search, MapPin, Star, Globe } from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
  Nunito_700Bold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";
import FloatingAIButton from "@/components/FloatingAIButton";

const { width: screenWidth } = Dimensions.get("window");

export default function SearchScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [searchQuery, setSearchQuery] = useState("");
  const [results, setResults] = useState([]);
  const [onlineResult, setOnlineResult] = useState(null);
  const [loading, setLoading] = useState(false);
  const [onlineLoading, setOnlineLoading] = useState(false);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_500Medium,
  });

  useEffect(() => {
    if (searchQuery.trim().length > 0) {
      const timer = setTimeout(() => {
        handleSearch();
      }, 500);
      return () => clearTimeout(timer);
    } else {
      setResults([]);
      setOnlineResult(null);
    }
  }, [searchQuery]);

  const handleSearch = async () => {
    // Search local database
    try {
      setLoading(true);
      const response = await fetch(
        `/api/destinations?search=${encodeURIComponent(searchQuery)}&limit=50`,
      );
      if (response.ok) {
        const data = await response.json();
        setResults(data.destinations || []);
      }
    } catch (error) {
      console.error("Error searching:", error);
    } finally {
      setLoading(false);
    }

    // Search online for additional context
    try {
      setOnlineLoading(true);
      const response = await fetch(
        `/api/destinations/search-online?query=${encodeURIComponent(searchQuery)}`,
      );
      if (response.ok) {
        const data = await response.json();
        setOnlineResult(data.destination);
      }
    } catch (error) {
      console.error("Error searching online:", error);
    } finally {
      setOnlineLoading(false);
    }
  };

  if (!fontsLoaded) {
    return null;
  }

  const handleBackPress = () => {
    router.back();
  };

  const handleResultPress = (id) => {
    router.push(`/destination/${id}`);
  };

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
    header: {
      paddingHorizontal: 20,
      paddingBottom: 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    headerRow: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 16,
    },
    backButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: theme.surface,
      justifyContent: "center",
      alignItems: "center",
      marginRight: 12,
    },
    searchBarContainer: {
      flex: 1,
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: theme.searchBackground,
      borderRadius: 22,
      paddingHorizontal: 16,
      paddingVertical: 12,
    },
    searchInput: {
      flex: 1,
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.text,
      marginLeft: 10,
    },
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      paddingHorizontal: 24,
      paddingTop: 20,
    },
    sectionTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 18,
      color: theme.text,
      marginBottom: 12,
      marginTop: 8,
      flexDirection: "row",
      alignItems: "center",
    },
    onlineCard: {
      backgroundColor: "#FFF7E6",
      borderRadius: 16,
      padding: 16,
      marginBottom: 24,
      borderWidth: 1,
      borderColor: "#FFE5B4",
    },
    onlineHeader: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 8,
    },
    onlineTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: "#1A1A1A",
      marginLeft: 8,
      flex: 1,
    },
    onlineDescription: {
      fontFamily: "Nunito_400Regular",
      fontSize: 14,
      color: "#666",
      lineHeight: 20,
      marginBottom: 12,
    },
    relatedSection: {
      marginTop: 8,
    },
    relatedLabel: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 13,
      color: "#1A1A1A",
      marginBottom: 6,
    },
    relatedItem: {
      fontFamily: "Nunito_400Regular",
      fontSize: 12,
      color: "#666",
      marginBottom: 3,
      lineHeight: 16,
    },
    separator: {
      height: 1,
      backgroundColor: theme.border,
      marginVertical: 16,
    },
    resultsHeader: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 20,
      color: theme.text,
      marginBottom: 16,
    },
    emptyState: {
      alignItems: "center",
      justifyContent: "center",
      paddingVertical: 60,
    },
    emptyText: {
      fontFamily: "Nunito_400Regular",
      fontSize: 16,
      color: theme.textSecondary,
      textAlign: "center",
    },
    resultCard: {
      flexDirection: "row",
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: 12,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: theme.border,
    },
    resultImage: {
      width: 80,
      height: 80,
      borderRadius: 12,
      marginRight: 12,
    },
    resultInfo: {
      flex: 1,
      justifyContent: "center",
    },
    resultName: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: theme.text,
      marginBottom: 4,
    },
    resultLocation: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 6,
    },
    resultLocationText: {
      fontFamily: "Nunito_400Regular",
      fontSize: 13,
      color: theme.textSecondary,
      marginLeft: 4,
    },
    resultRating: {
      flexDirection: "row",
      alignItems: "center",
    },
    resultRatingText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 13,
      color: theme.text,
      marginLeft: 4,
    },
    loadingContainer: {
      padding: 20,
      alignItems: "center",
    },
    loadingText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 14,
      color: theme.textSecondary,
      marginTop: 8,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <View style={styles.headerRow}>
          <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
            <ArrowLeft size={24} color={theme.icon} />
          </TouchableOpacity>

          <View style={styles.searchBarContainer}>
            <Search size={20} color={theme.searchPlaceholder} />
            <TextInput
              style={styles.searchInput}
              value={searchQuery}
              onChangeText={setSearchQuery}
              placeholder="Search destinations..."
              placeholderTextColor={theme.searchPlaceholder}
              autoFocus
            />
          </View>
        </View>
      </View>

      {/* Results */}
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 80 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        {/* Online Search Result */}
        {onlineResult && (
          <>
            <Text style={styles.sectionTitle}>
              <Globe size={18} color={theme.text} /> Online Travel Info
            </Text>
            <View style={styles.onlineCard}>
              <View style={styles.onlineHeader}>
                <Text style={styles.onlineTitle}>{onlineResult.title}</Text>
              </View>
              <Text style={styles.onlineDescription}>
                {onlineResult.description}
              </Text>

              {onlineResult.relatedResults &&
                onlineResult.relatedResults.length > 0 && (
                  <View style={styles.relatedSection}>
                    <Text style={styles.relatedLabel}>Related Info:</Text>
                    {onlineResult.relatedResults.map((result, idx) => (
                      <Text key={idx} style={styles.relatedItem}>
                        • {result.title}
                      </Text>
                    ))}
                  </View>
                )}
            </View>
          </>
        )}

        {onlineLoading && (
          <View style={styles.loadingContainer}>
            <ActivityIndicator color={theme.accent} />
            <Text style={styles.loadingText}>Searching online...</Text>
          </View>
        )}

        {/* Separator */}
        {onlineResult && results.length > 0 && (
          <View style={styles.separator} />
        )}

        {/* Local Database Results */}
        {searchQuery.trim().length > 0 && results.length > 0 && (
          <Text style={styles.resultsHeader}>
            {results.length}{" "}
            {results.length === 1 ? "destination" : "destinations"} in our
            collection
          </Text>
        )}

        {searchQuery.trim().length > 0 &&
          results.length === 0 &&
          !loading &&
          !onlineResult && (
            <View style={styles.emptyState}>
              <Text style={styles.emptyText}>
                No destinations found for "{searchQuery}"
              </Text>
            </View>
          )}

        {loading && (
          <View style={styles.loadingContainer}>
            <ActivityIndicator color={theme.accent} />
            <Text style={styles.loadingText}>Searching destinations...</Text>
          </View>
        )}

        {results.map((destination) => (
          <TouchableOpacity
            key={destination.id}
            style={styles.resultCard}
            onPress={() => handleResultPress(destination.id)}
            activeOpacity={0.7}
          >
            <Image
              source={{ uri: destination.image_url }}
              style={styles.resultImage}
              contentFit="cover"
            />

            <View style={styles.resultInfo}>
              <Text style={styles.resultName}>{destination.name}</Text>

              <View style={styles.resultLocation}>
                <MapPin size={12} color={theme.textSecondary} />
                <Text style={styles.resultLocationText}>
                  {destination.country}
                </Text>
              </View>

              <View style={styles.resultRating}>
                <Star size={12} color="#FFF630" fill="#FFF630" />
                <Text style={styles.resultRatingText}>
                  {destination.rating}
                </Text>
              </View>
            </View>
          </TouchableOpacity>
        ))}
      </ScrollView>

      {/* Floating AI Assistant Button */}
      <FloatingAIButton />
    </View>
  );
}
