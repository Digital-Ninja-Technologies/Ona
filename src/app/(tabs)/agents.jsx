import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  ActivityIndicator,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  ArrowLeft,
  Search,
  Star,
  MapPin,
  Clock,
  CheckCircle,
  Filter,
} from "lucide-react-native";
import {
  useFonts,
  Poppins_400Regular,
  Poppins_500Medium,
  Poppins_600SemiBold,
} from "@expo-google-fonts/poppins";
import { useTheme } from "@/utils/theme/useTheme";

export default function TravelAgentsScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [agents, setAgents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedFilter, setSelectedFilter] = useState("all");
  const [error, setError] = useState(null);

  const [fontsLoaded] = useFonts({
    Poppins_400Regular,
    Poppins_500Medium,
    Poppins_600SemiBold,
  });

  useEffect(() => {
    fetchAgents();
  }, [selectedFilter]);

  const fetchAgents = async () => {
    try {
      setLoading(true);
      setError(null);
      let url = "/api/travel-agents?limit=50";
      if (selectedFilter !== "all" && selectedFilter !== "") {
        url += `&minRating=${selectedFilter}`;
      }

      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(
          `Failed to fetch agents: ${response.status} ${response.statusText}`,
        );
      }
      const data = await response.json();

      // Ensure agents is always an array and validate each agent
      const validAgents = Array.isArray(data.agents)
        ? data.agents.filter(
            (agent) => agent && typeof agent === "object" && agent.id,
          )
        : [];

      setAgents(validAgents);
    } catch (error) {
      console.error("Error fetching travel agents:", error);
      setError(error.message);
      setAgents([]); // Set empty array on error
    } finally {
      setLoading(false);
    }
  };

  const handleAgentPress = (agentId) => {
    if (agentId) {
      router.push(`/travel-agent/${agentId}`);
    }
  };

  // Ensure agents is an array before filtering with comprehensive validation
  const filteredAgents = Array.isArray(agents)
    ? agents.filter((agent) => {
        if (!agent || typeof agent !== "object" || !agent.id) return false;

        if (!searchQuery) return true; // If no search query, include all valid agents

        const searchLower = searchQuery.toLowerCase();
        return (
          (agent.business_name &&
            typeof agent.business_name === "string" &&
            agent.business_name.toLowerCase().includes(searchLower)) ||
          (agent.bio &&
            typeof agent.bio === "string" &&
            agent.bio.toLowerCase().includes(searchLower)) ||
          (Array.isArray(agent.specialties) &&
            agent.specialties.some(
              (s) =>
                s &&
                typeof s === "string" &&
                s.toLowerCase().includes(searchLower),
            ))
        );
      })
    : [];

  // Helper function to safely render specialties
  const renderSpecialties = (specialties) => {
    if (!Array.isArray(specialties) || specialties.length === 0) {
      return null;
    }

    const validSpecialties = specialties
      .filter((specialty) => specialty && typeof specialty === "string")
      .slice(0, 3);

    if (validSpecialties.length === 0) {
      return null;
    }

    return (
      <View style={styles.specialtiesContainer}>
        {validSpecialties.map((specialty, index) => (
          <View key={`specialty-${index}`} style={styles.specialtyTag}>
            <Text style={styles.specialtyText}>{specialty}</Text>
          </View>
        ))}
      </View>
    );
  };

  if (!fontsLoaded) {
    return null;
  }

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
    header: {
      paddingHorizontal: 20,
      paddingBottom: 16,
      backgroundColor: theme.background,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    headerTop: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 16,
    },
    headerTitle: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: 24,
      color: theme.text,
      flex: 1,
    },
    searchContainer: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: theme.surface,
      borderRadius: 12,
      paddingHorizontal: 12,
      paddingVertical: 10,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: theme.border,
    },
    searchInput: {
      flex: 1,
      fontFamily: "Poppins_400Regular",
      fontSize: 15,
      color: theme.text,
      marginLeft: 8,
    },
    filterContainer: {
      flexDirection: "row",
      gap: 8,
    },
    filterButton: {
      paddingHorizontal: 16,
      paddingVertical: 8,
      borderRadius: 20,
      backgroundColor: theme.surface,
      borderWidth: 1,
      borderColor: theme.border,
    },
    filterButtonActive: {
      backgroundColor: theme.accent,
      borderColor: theme.accent,
    },
    filterText: {
      fontFamily: "Poppins_500Medium",
      fontSize: 13,
      color: theme.textSecondary,
    },
    filterTextActive: {
      color: "#FFFFFF",
    },
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      padding: 20,
    },
    agentCard: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: 16,
      marginBottom: 16,
      borderWidth: 1,
      borderColor: theme.border,
    },
    agentHeader: {
      flexDirection: "row",
      marginBottom: 12,
    },
    agentImage: {
      width: 60,
      height: 60,
      borderRadius: 30,
      backgroundColor: theme.border,
      marginRight: 12,
    },
    agentInfo: {
      flex: 1,
    },
    agentName: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: 18,
      color: theme.text,
      marginBottom: 4,
    },
    verifiedBadge: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 6,
    },
    verifiedText: {
      fontFamily: "Poppins_500Medium",
      fontSize: 13,
      color: "#10B981",
      marginLeft: 4,
    },
    ratingContainer: {
      flexDirection: "row",
      alignItems: "center",
    },
    ratingText: {
      fontFamily: "Poppins_500Medium",
      fontSize: 14,
      color: theme.text,
      marginLeft: 4,
      marginRight: 8,
    },
    reviewCount: {
      fontFamily: "Poppins_400Regular",
      fontSize: 13,
      color: theme.textSecondary,
    },
    agentBio: {
      fontFamily: "Poppins_400Regular",
      fontSize: 14,
      color: theme.textSecondary,
      lineHeight: 20,
      marginBottom: 12,
    },
    specialtiesContainer: {
      flexDirection: "row",
      flexWrap: "wrap",
      gap: 6,
      marginBottom: 12,
    },
    specialtyTag: {
      backgroundColor: theme.background,
      paddingHorizontal: 10,
      paddingVertical: 4,
      borderRadius: 12,
      borderWidth: 1,
      borderColor: theme.border,
    },
    specialtyText: {
      fontFamily: "Poppins_400Regular",
      fontSize: 12,
      color: theme.textSecondary,
    },
    agentFooter: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      paddingTop: 12,
      borderTopWidth: 1,
      borderTopColor: theme.border,
    },
    footerInfo: {
      flexDirection: "row",
      alignItems: "center",
      flex: 1,
    },
    footerText: {
      fontFamily: "Poppins_400Regular",
      fontSize: 12,
      color: theme.textSecondary,
      marginLeft: 4,
    },
    viewButton: {
      backgroundColor: theme.accent,
      paddingHorizontal: 20,
      paddingVertical: 8,
      borderRadius: 20,
    },
    viewButtonText: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: 13,
      color: "#FFFFFF",
    },
    loadingContainer: {
      flex: 1,
      justifyContent: "center",
      alignItems: "center",
    },
    emptyContainer: {
      flex: 1,
      justifyContent: "center",
      alignItems: "center",
      paddingTop: 60,
    },
    emptyText: {
      fontFamily: "Poppins_500Medium",
      fontSize: 16,
      color: theme.textSecondary,
      marginTop: 12,
    },
    errorContainer: {
      flex: 1,
      justifyContent: "center",
      alignItems: "center",
      paddingHorizontal: 20,
    },
    errorText: {
      fontFamily: "Poppins_500Medium",
      fontSize: 16,
      color: theme.textSecondary,
      textAlign: "center",
      marginTop: 12,
    },
    retryButton: {
      backgroundColor: theme.accent,
      paddingHorizontal: 20,
      paddingVertical: 10,
      borderRadius: 20,
      marginTop: 16,
    },
    retryButtonText: {
      fontFamily: "Poppins_600SemiBold",
      fontSize: 14,
      color: "#FFFFFF",
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <View style={styles.headerTop}>
          <Text style={styles.headerTitle}>Travel Agents</Text>
        </View>

        {/* Search Bar */}
        <View style={styles.searchContainer}>
          <Search size={20} color={theme.iconSecondary} />
          <TextInput
            style={styles.searchInput}
            placeholder="Search agents..."
            placeholderTextColor={theme.textSecondary}
            value={searchQuery}
            onChangeText={setSearchQuery}
          />
        </View>

        {/* Filters */}
        <ScrollView horizontal showsHorizontalScrollIndicator={false}>
          <View style={styles.filterContainer}>
            <TouchableOpacity
              style={[
                styles.filterButton,
                selectedFilter === "all" && styles.filterButtonActive,
              ]}
              onPress={() => setSelectedFilter("all")}
            >
              <Text
                style={[
                  styles.filterText,
                  selectedFilter === "all" && styles.filterTextActive,
                ]}
              >
                All Agents
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.filterButton,
                selectedFilter === "4.5" && styles.filterButtonActive,
              ]}
              onPress={() => setSelectedFilter("4.5")}
            >
              <Text
                style={[
                  styles.filterText,
                  selectedFilter === "4.5" && styles.filterTextActive,
                ]}
              >
                Top Rated
              </Text>
            </TouchableOpacity>
            <TouchableOpacity
              style={[
                styles.filterButton,
                selectedFilter === "4" && styles.filterButtonActive,
              ]}
              onPress={() => setSelectedFilter("4")}
            >
              <Text
                style={[
                  styles.filterText,
                  selectedFilter === "4" && styles.filterTextActive,
                ]}
              >
                4+ Stars
              </Text>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </View>

      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color={theme.accent} />
        </View>
      ) : error ? (
        <View style={styles.errorContainer}>
          <Search size={48} color={theme.iconSecondary} />
          <Text style={styles.errorText}>Failed to load agents: {error}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchAgents}>
            <Text style={styles.retryButtonText}>Retry</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <ScrollView
          style={styles.scrollView}
          contentContainerStyle={[
            styles.contentContainer,
            { paddingBottom: insets.bottom + 20 },
          ]}
          showsVerticalScrollIndicator={false}
        >
          {filteredAgents.length === 0 ? (
            <View style={styles.emptyContainer}>
              <Search size={48} color={theme.iconSecondary} />
              <Text style={styles.emptyText}>No agents found</Text>
            </View>
          ) : (
            filteredAgents.map((agent) => {
              if (!agent || !agent.id) return null;

              return (
                <TouchableOpacity
                  key={`agent-${agent.id}`}
                  style={styles.agentCard}
                  onPress={() => handleAgentPress(agent.id)}
                  activeOpacity={0.8}
                >
                  <View style={styles.agentHeader}>
                    <Image
                      source={{
                        uri:
                          agent.profile_image ||
                          agent.user_profile_image ||
                          "https://via.placeholder.com/60",
                      }}
                      style={styles.agentImage}
                      contentFit="cover"
                      transition={100}
                    />
                    <View style={styles.agentInfo}>
                      <Text style={styles.agentName} numberOfLines={1}>
                        {agent.business_name || "Unknown Agent"}
                      </Text>
                      {agent.is_verified && (
                        <View style={styles.verifiedBadge}>
                          <CheckCircle size={14} color="#10B981" />
                          <Text style={styles.verifiedText}>
                            Verified Agent
                          </Text>
                        </View>
                      )}
                      <View style={styles.ratingContainer}>
                        <Star size={16} color="#FFC107" fill="#FFC107" />
                        <Text style={styles.ratingText}>
                          {typeof agent.rating === "number"
                            ? agent.rating.toFixed(1)
                            : "0.0"}
                        </Text>
                        <Text style={styles.reviewCount}>
                          ({agent.total_reviews || 0} reviews)
                        </Text>
                      </View>
                    </View>
                  </View>

                  {agent.bio && typeof agent.bio === "string" && (
                    <Text style={styles.agentBio} numberOfLines={2}>
                      {agent.bio}
                    </Text>
                  )}

                  {renderSpecialties(agent.specialties)}

                  <View style={styles.agentFooter}>
                    <View style={styles.footerInfo}>
                      <Clock size={14} color={theme.iconSecondary} />
                      <Text style={styles.footerText}>
                        Responds in {agent.response_time_hours || 24}h
                      </Text>
                    </View>
                    <View style={styles.viewButton}>
                      <Text style={styles.viewButtonText}>View Profile</Text>
                    </View>
                  </View>
                </TouchableOpacity>
              );
            })
          )}
        </ScrollView>
      )}
    </View>
  );
}
