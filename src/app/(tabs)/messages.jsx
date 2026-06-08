import React, { useState, useEffect } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
  RefreshControl,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import { MessageCircle, User } from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_600SemiBold,
  Nunito_700Bold,
} from "@expo-google-fonts/nunito";
import { Fredoka_600SemiBold } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";
import useUser from "@/utils/auth/useUser";

export default function MessagesScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { data: user } = useUser();
  const [conversations, setConversations] = useState([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_600SemiBold,
    Nunito_700Bold,
    Fredoka_600SemiBold,
  });

  const fetchConversations = async () => {
    try {
      const response = await fetch("/api/conversations");
      if (!response.ok) throw new Error("Failed to fetch conversations");
      const data = await response.json();
      setConversations(data.conversations || []);
    } catch (error) {
      console.error("Error fetching conversations:", error);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    if (user) {
      fetchConversations();
    }
  }, [user]);

  const onRefresh = () => {
    setRefreshing(true);
    fetchConversations();
  };

  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now - date;
    const hours = Math.floor(diff / (1000 * 60 * 60));
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));

    if (hours < 1) return "Just now";
    if (hours < 24) return `${hours}h ago`;
    if (days < 7) return `${days}d ago`;
    return date.toLocaleDateString();
  };

  if (!fontsLoaded) {
    return null;
  }

  if (!user) {
    return (
      <View
        style={{
          flex: 1,
          backgroundColor: theme.background,
          paddingTop: insets.top,
        }}
      >
        <StatusBar style={theme.statusBarStyle} />
        <View
          style={{
            flex: 1,
            justifyContent: "center",
            alignItems: "center",
            paddingHorizontal: 40,
          }}
        >
          <MessageCircle size={64} color={theme.textSecondary} />
          <Text
            style={{
              fontFamily: "Nunito_600SemiBold",
              fontSize: 18,
              color: theme.text,
              marginTop: 16,
              textAlign: "center",
            }}
          >
            Sign in to view messages
          </Text>
          <Text
            style={{
              fontFamily: "Nunito_400Regular",
              fontSize: 14,
              color: theme.textSecondary,
              marginTop: 8,
              textAlign: "center",
            }}
          >
            Connect with travelers and share experiences
          </Text>
        </View>
      </View>
    );
  }

  return (
    <View style={{ flex: 1, backgroundColor: theme.background }}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View
        style={{
          paddingTop: insets.top + 16,
          paddingHorizontal: 20,
          paddingBottom: 16,
          borderBottomWidth: 1,
          borderBottomColor: theme.border,
        }}
      >
        <Text
          style={{
            fontFamily: "Fredoka_600SemiBold",
            fontSize: 28,
            color: theme.text,
          }}
        >
          Messages
        </Text>
      </View>

      {/* Conversations List */}
      <ScrollView
        style={{ flex: 1 }}
        contentContainerStyle={{ paddingBottom: insets.bottom + 20 }}
        showsVerticalScrollIndicator={false}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor={theme.primary}
          />
        }
      >
        {loading ? (
          <View style={{ paddingVertical: 40, alignItems: "center" }}>
            <ActivityIndicator size="large" color="#FF6B9D" />
          </View>
        ) : conversations.length === 0 ? (
          <View
            style={{
              paddingVertical: 60,
              paddingHorizontal: 40,
              alignItems: "center",
            }}
          >
            <MessageCircle size={64} color={theme.textSecondary} />
            <Text
              style={{
                fontFamily: "Nunito_600SemiBold",
                fontSize: 18,
                color: theme.text,
                marginTop: 16,
                textAlign: "center",
              }}
            >
              No messages yet
            </Text>
            <Text
              style={{
                fontFamily: "Nunito_400Regular",
                fontSize: 14,
                color: theme.textSecondary,
                marginTop: 8,
                textAlign: "center",
              }}
            >
              Start chatting with other travelers from the community tab
            </Text>
          </View>
        ) : (
          conversations.map((conversation) => (
            <TouchableOpacity
              key={conversation.id}
              onPress={() => router.push(`/chat/${conversation.id}`)}
              style={{
                flexDirection: "row",
                paddingHorizontal: 20,
                paddingVertical: 16,
                borderBottomWidth: 1,
                borderBottomColor: theme.border,
                backgroundColor:
                  conversation.unread_count > 0 ? theme.surface : "transparent",
              }}
            >
              {/* Avatar */}
              <View
                style={{
                  width: 56,
                  height: 56,
                  borderRadius: 28,
                  backgroundColor: "#FF6B9D",
                  justifyContent: "center",
                  alignItems: "center",
                  marginRight: 12,
                }}
              >
                {conversation.other_user_image ? (
                  <Text
                    style={{
                      fontFamily: "Nunito_700Bold",
                      fontSize: 20,
                      color: "#1A1A1A",
                    }}
                  >
                    {conversation.other_user_name?.charAt(0).toUpperCase()}
                  </Text>
                ) : (
                  <User size={28} color="#1A1A1A" />
                )}
              </View>

              {/* Content */}
              <View style={{ flex: 1, justifyContent: "center" }}>
                <View
                  style={{
                    flexDirection: "row",
                    justifyContent: "space-between",
                    marginBottom: 4,
                  }}
                >
                  <Text
                    style={{
                      fontFamily: "Nunito_600SemiBold",
                      fontSize: 16,
                      color: theme.text,
                      flex: 1,
                    }}
                    numberOfLines={1}
                  >
                    {conversation.other_user_name || "Unknown User"}
                  </Text>
                  <Text
                    style={{
                      fontFamily: "Nunito_400Regular",
                      fontSize: 12,
                      color: theme.textSecondary,
                      marginLeft: 8,
                    }}
                  >
                    {formatTime(conversation.last_message_at)}
                  </Text>
                </View>

                <View
                  style={{
                    flexDirection: "row",
                    alignItems: "center",
                    justifyContent: "space-between",
                  }}
                >
                  <Text
                    style={{
                      fontFamily: "Nunito_400Regular",
                      fontSize: 14,
                      color: theme.textSecondary,
                      flex: 1,
                    }}
                    numberOfLines={1}
                  >
                    {conversation.last_message_sender_id === user.id
                      ? "You: "
                      : ""}
                    {conversation.last_message || "No messages yet"}
                  </Text>

                  {conversation.unread_count > 0 && (
                    <View
                      style={{
                        backgroundColor: "#FF6B9D",
                        borderRadius: 12,
                        paddingHorizontal: 8,
                        paddingVertical: 2,
                        marginLeft: 8,
                        minWidth: 24,
                        alignItems: "center",
                      }}
                    >
                      <Text
                        style={{
                          fontFamily: "Nunito_700Bold",
                          fontSize: 12,
                          color: "#1A1A1A",
                        }}
                      >
                        {conversation.unread_count}
                      </Text>
                    </View>
                  )}
                </View>
              </View>
            </TouchableOpacity>
          ))
        )}
      </ScrollView>
    </View>
  );
}
