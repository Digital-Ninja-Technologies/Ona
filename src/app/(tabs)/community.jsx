import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  RefreshControl,
} from "react-native";
import { Image } from "expo-image";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import {
  Heart,
  MessageCircle,
  Share2,
  MapPin,
  Star,
  Plus,
} from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { InstrumentSans_500Medium } from "@expo-google-fonts/instrument-sans";
import { useTheme } from "@/utils/theme/useTheme";
import FloatingAIButton from "@/components/FloatingAIButton";

const POST_TYPES = [
  { id: "all", label: "All Posts" },
  { id: "story", label: "Stories" },
  { id: "tip", label: "Tips" },
  { id: "question", label: "Questions" },
];

export default function CommunityScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [selectedType, setSelectedType] = useState("all");
  const [posts, setPosts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
    InstrumentSans_500Medium,
  });

  useEffect(() => {
    fetchPosts();
  }, [selectedType]);

  const fetchPosts = async () => {
    try {
      setLoading(true);
      const typeParam = selectedType !== "all" ? `&type=${selectedType}` : "";
      const response = await fetch(`/api/posts?limit=50${typeParam}`);
      if (!response.ok) {
        throw new Error("Failed to fetch posts");
      }
      const data = await response.json();
      setPosts(data.posts || []);
    } catch (error) {
      console.error("Error fetching posts:", error);
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await fetchPosts();
    setRefreshing(false);
  };

  const handleLike = async (postId) => {
    // Toggle like - would need API endpoint
    console.log("Like post:", postId);
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
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    headerRow: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      marginBottom: 16,
    },
    headerTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 28,
      color: theme.text,
    },
    createButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: "#FF6B9D",
      justifyContent: "center",
      alignItems: "center",
    },
    filterScroll: {
      marginBottom: 8,
    },
    filterChips: {
      flexDirection: "row",
      gap: 8,
      paddingRight: 20,
    },
    filterChip: {
      backgroundColor: theme.surface,
      borderRadius: 20,
      paddingVertical: 8,
      paddingHorizontal: 16,
      borderWidth: 1,
      borderColor: theme.border,
    },
    filterChipActive: {
      backgroundColor: "#FF6B9D",
      borderColor: "#E5528A",
    },
    filterChipText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 13,
      color: theme.text,
    },
    filterChipTextActive: {
      color: "#1A1A1A",
    },
    scrollView: {
      flex: 1,
    },
    contentContainer: {
      paddingHorizontal: 20,
      paddingTop: 16,
    },
    postCard: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: 16,
      marginBottom: 16,
      borderWidth: 1,
      borderColor: theme.border,
    },
    postHeader: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 12,
    },
    avatar: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: theme.accent,
      marginRight: 12,
    },
    postHeaderInfo: {
      flex: 1,
    },
    userName: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 15,
      color: theme.text,
      marginBottom: 2,
    },
    postMeta: {
      fontFamily: "Nunito_400Regular",
      fontSize: 12,
      color: theme.textSecondary,
    },
    postTypeBadge: {
      backgroundColor: "#FF6B9D",
      borderRadius: 12,
      paddingHorizontal: 12,
      paddingVertical: 4,
    },
    postTypeBadgeText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 11,
      color: "#1A1A1A",
    },
    postTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 17,
      color: theme.text,
      marginBottom: 8,
    },
    postContent: {
      fontFamily: "Nunito_400Regular",
      fontSize: 14,
      color: theme.textSecondary,
      lineHeight: 20,
      marginBottom: 12,
    },
    postDestination: {
      flexDirection: "row",
      alignItems: "center",
      marginBottom: 16,
    },
    postDestinationText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 13,
      color: "#FF6B9D",
      marginLeft: 4,
    },
    postActions: {
      flexDirection: "row",
      alignItems: "center",
      gap: 20,
      paddingTop: 12,
      borderTopWidth: 1,
      borderTopColor: theme.border,
    },
    actionButton: {
      flexDirection: "row",
      alignItems: "center",
      gap: 6,
    },
    actionText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 13,
      color: theme.textSecondary,
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
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <View style={styles.headerRow}>
          <Text style={styles.headerTitle}>Community</Text>
          <TouchableOpacity style={styles.createButton}>
            <Plus size={24} color="#1A1A1A" />
          </TouchableOpacity>
        </View>

        {/* Filter */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          style={styles.filterScroll}
          contentContainerStyle={styles.filterChips}
        >
          {POST_TYPES.map((type) => (
            <TouchableOpacity
              key={type.id}
              style={[
                styles.filterChip,
                selectedType === type.id && styles.filterChipActive,
              ]}
              onPress={() => setSelectedType(type.id)}
            >
              <Text
                style={[
                  styles.filterChipText,
                  selectedType === type.id && styles.filterChipTextActive,
                ]}
              >
                {type.label}
              </Text>
            </TouchableOpacity>
          ))}
        </ScrollView>
      </View>

      {/* Posts */}
      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 100 },
        ]}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={handleRefresh}
            tintColor="#FF6B9D"
          />
        }
      >
        {posts.length === 0 && !loading && (
          <View style={styles.emptyState}>
            <Text style={styles.emptyText}>
              No posts yet. Be the first to share!
            </Text>
          </View>
        )}

        {posts.map((post) => (
          <View key={post.id} style={styles.postCard}>
            <View style={styles.postHeader}>
              <View style={styles.avatar}>
                {post.profile_image && (
                  <Image
                    source={{ uri: post.profile_image }}
                    style={{ width: 40, height: 40, borderRadius: 20 }}
                    contentFit="cover"
                  />
                )}
              </View>

              <View style={styles.postHeaderInfo}>
                <Text style={styles.userName}>
                  {post.user_name || "Traveler"}
                </Text>
                <Text style={styles.postMeta}>
                  {new Date(post.created_at).toLocaleDateString()}
                </Text>
              </View>

              <View style={styles.postTypeBadge}>
                <Text style={styles.postTypeBadgeText}>
                  {post.post_type.toUpperCase()}
                </Text>
              </View>
            </View>

            {post.title && <Text style={styles.postTitle}>{post.title}</Text>}

            <Text style={styles.postContent} numberOfLines={4}>
              {post.content}
            </Text>

            {post.destination_name && (
              <View style={styles.postDestination}>
                <MapPin size={14} color={theme.accent} />
                <Text style={styles.postDestinationText}>
                  {post.destination_name}
                </Text>
              </View>
            )}

            <View style={styles.postActions}>
              <TouchableOpacity
                style={styles.actionButton}
                onPress={() => handleLike(post.id)}
              >
                <Heart size={18} color={theme.textSecondary} />
                <Text style={styles.actionText}>{post.likes_count || 0}</Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.actionButton}>
                <MessageCircle size={18} color={theme.textSecondary} />
                <Text style={styles.actionText}>Reply</Text>
              </TouchableOpacity>

              <TouchableOpacity style={styles.actionButton}>
                <Share2 size={18} color={theme.textSecondary} />
              </TouchableOpacity>
            </View>
          </View>
        ))}
      </ScrollView>

      {/* Floating AI Assistant Button */}
      <FloatingAIButton />
    </View>
  );
}
