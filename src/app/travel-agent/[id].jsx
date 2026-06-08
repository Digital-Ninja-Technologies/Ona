import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  ActivityIndicator,
  Alert,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import {
  ArrowLeft,
  Star,
  MessageCircle,
  CheckCircle,
  Award,
  Calendar,
  Languages,
} from "lucide-react-native";
import {
  useFonts,
  Poppins_400Regular,
  Poppins_500Medium,
  Poppins_600SemiBold,
} from "@expo-google-fonts/poppins";
import { useTheme } from "@/utils/theme/useTheme";
import { useUser } from "@/utils/auth/useUser";

export default function TravelAgentDetailScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { id } = useLocalSearchParams();
  const { data: currentUser } = useUser();
  const [agent, setAgent] = useState(null);
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [fontsLoaded] = useFonts({
    Poppins_400Regular,
    Poppins_500Medium,
    Poppins_600SemiBold,
  });

  useEffect(() => {
    if (id) {
      fetchAgentDetails();
    }
  }, [id]);

  const fetchAgentDetails = async () => {
    try {
      setLoading(true);
      setError(null);
      const response = await fetch(`/api/travel-agents/${id}`);
      if (!response.ok) {
        throw new Error("Failed to fetch agent details");
      }
      const data = await response.json();

      // Validate agent data
      if (!data.agent || typeof data.agent !== "object") {
        throw new Error("Invalid agent data");
      }

      setAgent(data.agent);
      setReviews(Array.isArray(data.reviews) ? data.reviews : []);
    } catch (error) {
      console.error("Error fetching agent details:", error);
      setError(error.message || "Failed to load agent");
    } finally {
      setLoading(false);
    }
  };

  const handleStartChat = async () => {
    if (!currentUser) {
      router.push("/auth/signin");
      return;
    }

    if (!agent || !agent.user_id) {
      Alert.alert(
        "Error",
        "Unable to start chat. Agent information is incomplete.",
      );
      return;
    }

    try {
      const response = await fetch("/api/conversations", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user1_id: currentUser.id,
          user2_id: agent.user_id,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to create conversation");
      }

      const data = await response.json();
      if (data.conversation && data.conversation.id) {
        router.push(`/chat/${data.conversation.id}`);
      }
    } catch (error) {
      console.error("Error starting chat:", error);
      Alert.alert("Error", "Failed to start chat. Please try again.");
    }
  };

  if (!fontsLoaded || loading) {
    return (
      <View
        style={{
          flex: 1,
          backgroundColor: theme.background,
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <ActivityIndicator size="large" color={theme.accent} />
      </View>
    );
  }

  if (error || !agent) {
    return (
      <View
        style={{
          flex: 1,
          backgroundColor: theme.background,
        }}
      >
        <StatusBar style={theme.statusBarStyle} />
        <View
          style={{
            position: "absolute",
            top: insets.top + 16,
            left: 20,
            zIndex: 10,
          }}
        >
          <TouchableOpacity
            style={{
              width: 40,
              height: 40,
              borderRadius: 20,
              backgroundColor: theme.surface,
              justifyContent: "center",
              alignItems: "center",
            }}
            onPress={() => router.back()}
          >
            <ArrowLeft size={20} color={theme.text} />
          </TouchableOpacity>
        </View>
        <View
          style={{
            flex: 1,
            justifyContent: "center",
            alignItems: "center",
            padding: 20,
          }}
        >
          <Text
            style={{
              fontFamily: "Poppins_600SemiBold",
              fontSize: 18,
              color: theme.text,
              marginBottom: 8,
              textAlign: "center",
            }}
          >
            {error || "Agent not found"}
          </Text>
          <TouchableOpacity
            style={{
              backgroundColor: theme.accent,
              paddingHorizontal: 24,
              paddingVertical: 12,
              borderRadius: 12,
              marginTop: 16,
            }}
            onPress={() => router.back()}
          >
            <Text
              style={{
                fontFamily: "Poppins_600SemiBold",
                fontSize: 14,
                color: "#FFFFFF",
              }}
            >
              Go Back
            </Text>
          </TouchableOpacity>
        </View>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: theme.background }}>
      <StatusBar style="light" />

      {/* Header */}
      <View
        style={{
          position: "absolute",
          top: insets.top + 16,
          left: 20,
          right: 20,
          zIndex: 10,
          flexDirection: "row",
          justifyContent: "space-between",
        }}
      >
        <TouchableOpacity
          style={{
            width: 40,
            height: 40,
            borderRadius: 20,
            backgroundColor: "rgba(0,0,0,0.5)",
            justifyContent: "center",
            alignItems: "center",
          }}
          onPress={() => router.back()}
        >
          <ArrowLeft size={20} color="#FFFFFF" />
        </TouchableOpacity>
      </View>

      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ paddingBottom: insets.bottom + 20 }}
      >
        {/* Cover Image */}
        <Image
          source={{
            uri:
              agent.profile_image ||
              agent.user_profile_image ||
              "https://via.placeholder.com/400x200",
          }}
          style={{
            width: "100%",
            height: 200,
            backgroundColor: theme.surface,
          }}
          contentFit="cover"
          transition={100}
        />

        {/* Content */}
        <View style={{ padding: 20 }}>
          {/* Profile Section */}
          <View
            style={{ alignItems: "center", marginTop: -40, marginBottom: 20 }}
          >
            <Image
              source={{
                uri:
                  agent.profile_image ||
                  agent.user_profile_image ||
                  "https://via.placeholder.com/100",
              }}
              style={{
                width: 100,
                height: 100,
                borderRadius: 50,
                backgroundColor: theme.surface,
                borderWidth: 4,
                borderColor: theme.background,
              }}
              contentFit="cover"
              transition={100}
            />
            <Text
              style={{
                fontFamily: "Poppins_600SemiBold",
                fontSize: 24,
                color: theme.text,
                marginTop: 12,
                textAlign: "center",
              }}
            >
              {agent.business_name || "Travel Agent"}
            </Text>
            {agent.is_verified && (
              <View
                style={{
                  flexDirection: "row",
                  alignItems: "center",
                  marginTop: 6,
                }}
              >
                <CheckCircle size={18} color="#10B981" />
                <Text
                  style={{
                    fontFamily: "Poppins_500Medium",
                    fontSize: 14,
                    color: "#10B981",
                    marginLeft: 6,
                  }}
                >
                  Verified Agent
                </Text>
              </View>
            )}
            <View
              style={{
                flexDirection: "row",
                alignItems: "center",
                justifyContent: "center",
                marginTop: 8,
              }}
            >
              <Star size={20} color="#FFC107" fill="#FFC107" />
              <Text
                style={{
                  fontFamily: "Poppins_600SemiBold",
                  fontSize: 18,
                  color: theme.text,
                  marginLeft: 6,
                  marginRight: 4,
                }}
              >
                {typeof agent.rating === "number"
                  ? agent.rating.toFixed(1)
                  : "0.0"}
              </Text>
              <Text
                style={{
                  fontFamily: "Poppins_400Regular",
                  fontSize: 14,
                  color: theme.textSecondary,
                }}
              >
                ({agent.total_reviews || 0} reviews)
              </Text>
            </View>

            {/* Chat Button */}
            <TouchableOpacity
              style={{
                backgroundColor: theme.accent,
                flexDirection: "row",
                alignItems: "center",
                justifyContent: "center",
                paddingVertical: 14,
                borderRadius: 12,
                marginTop: 16,
                marginBottom: 24,
                width: "100%",
              }}
              onPress={handleStartChat}
              activeOpacity={0.8}
            >
              <MessageCircle size={20} color="#FFFFFF" />
              <Text
                style={{
                  fontFamily: "Poppins_600SemiBold",
                  fontSize: 16,
                  color: "#FFFFFF",
                  marginLeft: 8,
                }}
              >
                Chat with Agent
              </Text>
            </TouchableOpacity>
          </View>

          {/* About Section */}
          {agent.bio && typeof agent.bio === "string" && (
            <View style={{ marginBottom: 24 }}>
              <Text
                style={{
                  fontFamily: "Poppins_600SemiBold",
                  fontSize: 18,
                  color: theme.text,
                  marginBottom: 12,
                }}
              >
                About
              </Text>
              <Text
                style={{
                  fontFamily: "Poppins_400Regular",
                  fontSize: 15,
                  color: theme.textSecondary,
                  lineHeight: 22,
                }}
              >
                {agent.bio}
              </Text>
            </View>
          )}

          {/* Details Section */}
          <View style={{ marginBottom: 24 }}>
            <Text
              style={{
                fontFamily: "Poppins_600SemiBold",
                fontSize: 18,
                color: theme.text,
                marginBottom: 12,
              }}
            >
              Details
            </Text>
            <View
              style={{
                flexDirection: "row",
                alignItems: "center",
                marginBottom: 12,
              }}
            >
              <Award size={20} color={theme.iconSecondary} />
              <Text
                style={{
                  fontFamily: "Poppins_500Medium",
                  fontSize: 14,
                  color: theme.text,
                  marginLeft: 10,
                  flex: 1,
                }}
              >
                Experience
              </Text>
              <Text
                style={{
                  fontFamily: "Poppins_400Regular",
                  fontSize: 14,
                  color: theme.textSecondary,
                }}
              >
                {agent.years_experience || 0} years
              </Text>
            </View>
            <View
              style={{
                flexDirection: "row",
                alignItems: "center",
                marginBottom: 12,
              }}
            >
              <Calendar size={20} color={theme.iconSecondary} />
              <Text
                style={{
                  fontFamily: "Poppins_500Medium",
                  fontSize: 14,
                  color: theme.text,
                  marginLeft: 10,
                  flex: 1,
                }}
              >
                Response Time
              </Text>
              <Text
                style={{
                  fontFamily: "Poppins_400Regular",
                  fontSize: 14,
                  color: theme.textSecondary,
                }}
              >
                {agent.response_time_hours || 24} hours
              </Text>
            </View>
            {Array.isArray(agent.languages_spoken) &&
              agent.languages_spoken.length > 0 && (
                <View
                  style={{
                    flexDirection: "row",
                    alignItems: "center",
                    marginBottom: 12,
                  }}
                >
                  <Languages size={20} color={theme.iconSecondary} />
                  <Text
                    style={{
                      fontFamily: "Poppins_500Medium",
                      fontSize: 14,
                      color: theme.text,
                      marginLeft: 10,
                      flex: 1,
                    }}
                  >
                    Languages
                  </Text>
                  <Text
                    style={{
                      fontFamily: "Poppins_400Regular",
                      fontSize: 14,
                      color: theme.textSecondary,
                    }}
                  >
                    {agent.languages_spoken.join(", ")}
                  </Text>
                </View>
              )}
          </View>

          {/* Specialties */}
          {Array.isArray(agent.specialties) && agent.specialties.length > 0 && (
            <View style={{ marginBottom: 24 }}>
              <Text
                style={{
                  fontFamily: "Poppins_600SemiBold",
                  fontSize: 18,
                  color: theme.text,
                  marginBottom: 12,
                }}
              >
                Specialties
              </Text>
              <View style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}>
                {agent.specialties.map((specialty, index) => (
                  <View
                    key={`specialty-${index}`}
                    style={{
                      backgroundColor: theme.surface,
                      paddingHorizontal: 12,
                      paddingVertical: 6,
                      borderRadius: 16,
                      borderWidth: 1,
                      borderColor: theme.border,
                    }}
                  >
                    <Text
                      style={{
                        fontFamily: "Poppins_400Regular",
                        fontSize: 13,
                        color: theme.textSecondary,
                      }}
                    >
                      {specialty}
                    </Text>
                  </View>
                ))}
              </View>
            </View>
          )}

          {/* Countries Expertise */}
          {Array.isArray(agent.countries_expertise) &&
            agent.countries_expertise.length > 0 && (
              <View style={{ marginBottom: 24 }}>
                <Text
                  style={{
                    fontFamily: "Poppins_600SemiBold",
                    fontSize: 18,
                    color: theme.text,
                    marginBottom: 12,
                  }}
                >
                  Countries of Expertise
                </Text>
                <View
                  style={{ flexDirection: "row", flexWrap: "wrap", gap: 8 }}
                >
                  {agent.countries_expertise.map((country, index) => (
                    <View
                      key={`country-${index}`}
                      style={{
                        backgroundColor: theme.surface,
                        paddingHorizontal: 12,
                        paddingVertical: 6,
                        borderRadius: 16,
                        borderWidth: 1,
                        borderColor: theme.border,
                      }}
                    >
                      <Text
                        style={{
                          fontFamily: "Poppins_400Regular",
                          fontSize: 13,
                          color: theme.textSecondary,
                        }}
                      >
                        {country}
                      </Text>
                    </View>
                  ))}
                </View>
              </View>
            )}

          {/* Reviews */}
          {Array.isArray(reviews) && reviews.length > 0 && (
            <View style={{ marginBottom: 24 }}>
              <Text
                style={{
                  fontFamily: "Poppins_600SemiBold",
                  fontSize: 18,
                  color: theme.text,
                  marginBottom: 12,
                }}
              >
                Reviews ({reviews.length})
              </Text>
              {reviews.map((review) => {
                if (!review || !review.id) return null;

                return (
                  <View
                    key={`review-${review.id}`}
                    style={{
                      backgroundColor: theme.surface,
                      borderRadius: 12,
                      padding: 16,
                      marginBottom: 12,
                      borderWidth: 1,
                      borderColor: theme.border,
                    }}
                  >
                    <View style={{ flexDirection: "row", marginBottom: 8 }}>
                      <Image
                        source={{
                          uri:
                            review.reviewer_image ||
                            "https://via.placeholder.com/40",
                        }}
                        style={{
                          width: 40,
                          height: 40,
                          borderRadius: 20,
                          backgroundColor: theme.border,
                          marginRight: 12,
                        }}
                        contentFit="cover"
                        transition={100}
                      />
                      <View style={{ flex: 1 }}>
                        <Text
                          style={{
                            fontFamily: "Poppins_600SemiBold",
                            fontSize: 14,
                            color: theme.text,
                            marginBottom: 2,
                          }}
                        >
                          {review.reviewer_name || "Anonymous"}
                        </Text>
                        <Text
                          style={{
                            fontFamily: "Poppins_400Regular",
                            fontSize: 12,
                            color: theme.textSecondary,
                          }}
                        >
                          {review.created_at
                            ? new Date(review.created_at).toLocaleDateString()
                            : ""}
                        </Text>
                      </View>
                    </View>
                    <View
                      style={{
                        flexDirection: "row",
                        alignItems: "center",
                        marginBottom: 8,
                      }}
                    >
                      {[...Array(5)].map((_, i) => (
                        <Star
                          key={`star-${i}`}
                          size={14}
                          color="#FFC107"
                          fill={i < (review.rating || 0) ? "#FFC107" : "none"}
                          style={{ marginRight: 2 }}
                        />
                      ))}
                    </View>
                    {review.comment && typeof review.comment === "string" && (
                      <Text
                        style={{
                          fontFamily: "Poppins_400Regular",
                          fontSize: 14,
                          color: theme.textSecondary,
                          lineHeight: 20,
                        }}
                      >
                        {review.comment}
                      </Text>
                    )}
                  </View>
                );
              })}
            </View>
          )}
        </View>
      </ScrollView>
    </View>
  );
}
