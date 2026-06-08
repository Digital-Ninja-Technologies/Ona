import React, { useState, useRef, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router, useLocalSearchParams } from "expo-router";
import { ArrowLeft, Send, User } from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { useTheme } from "@/utils/theme/useTheme";
import useUser from "@/utils/auth/useUser";

export default function ChatScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const { id: conversationId } = useLocalSearchParams();
  const { data: user } = useUser();
  const [messages, setMessages] = useState([]);
  const [otherUser, setOtherUser] = useState(null);
  const [inputText, setInputText] = useState("");
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const scrollViewRef = useRef(null);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_600SemiBold,
  });

  const fetchMessages = async () => {
    try {
      const response = await fetch(`/api/conversations/${conversationId}`);
      if (!response.ok) throw new Error("Failed to fetch messages");
      const data = await response.json();
      setMessages(data.messages || []);
      setOtherUser(data.otherUser);
    } catch (error) {
      console.error("Error fetching messages:", error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (user && conversationId) {
      fetchMessages();

      // Poll for new messages every 3 seconds
      const interval = setInterval(fetchMessages, 3000);
      return () => clearInterval(interval);
    }
  }, [user, conversationId]);

  useEffect(() => {
    scrollViewRef.current?.scrollToEnd({ animated: true });
  }, [messages]);

  const handleSend = async () => {
    if (!inputText.trim() || sending) return;

    const messageContent = inputText.trim();
    setInputText("");
    setSending(true);

    try {
      const response = await fetch("/api/messages", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          conversationId,
          content: messageContent,
        }),
      });

      if (!response.ok) throw new Error("Failed to send message");

      // Refresh messages
      await fetchMessages();
    } catch (error) {
      console.error("Error sending message:", error);
      setInputText(messageContent);
    } finally {
      setSending(false);
    }
  };

  const formatTime = (timestamp) => {
    const date = new Date(timestamp);
    return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  };

  if (!fontsLoaded) {
    return null;
  }

  return (
    <View style={{ flex: 1, backgroundColor: theme.background }}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View
        style={{
          flexDirection: "row",
          alignItems: "center",
          paddingTop: insets.top + 16,
          paddingHorizontal: 20,
          paddingBottom: 16,
          borderBottomWidth: 1,
          borderBottomColor: theme.border,
        }}
      >
        <TouchableOpacity
          onPress={() => router.back()}
          style={{
            width: 40,
            height: 40,
            borderRadius: 20,
            backgroundColor: theme.surface,
            justifyContent: "center",
            alignItems: "center",
            marginRight: 12,
          }}
        >
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>

        {/* Other user info */}
        <View
          style={{
            width: 44,
            height: 44,
            borderRadius: 22,
            backgroundColor: "#FF6B9D",
            justifyContent: "center",
            alignItems: "center",
            marginRight: 12,
          }}
        >
          {otherUser?.profile_image ? (
            <Text
              style={{
                fontFamily: "Nunito_600SemiBold",
                fontSize: 18,
                color: "#1A1A1A",
              }}
            >
              {otherUser.name?.charAt(0).toUpperCase()}
            </Text>
          ) : (
            <User size={24} color="#1A1A1A" />
          )}
        </View>

        <Text
          style={{
            fontFamily: "Nunito_600SemiBold",
            fontSize: 18,
            color: theme.text,
            flex: 1,
          }}
        >
          {otherUser?.name || "Loading..."}
        </Text>
      </View>

      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={0}
      >
        {/* Messages */}
        <ScrollView
          ref={scrollViewRef}
          style={{ flex: 1 }}
          contentContainerStyle={{ paddingHorizontal: 20, paddingVertical: 20 }}
          showsVerticalScrollIndicator={false}
        >
          {loading ? (
            <View style={{ paddingVertical: 40, alignItems: "center" }}>
              <ActivityIndicator size="large" color="#FF6B9D" />
            </View>
          ) : messages.length === 0 ? (
            <View
              style={{
                paddingVertical: 60,
                paddingHorizontal: 40,
                alignItems: "center",
              }}
            >
              <Text
                style={{
                  fontFamily: "Nunito_600SemiBold",
                  fontSize: 16,
                  color: theme.textSecondary,
                  textAlign: "center",
                }}
              >
                No messages yet. Say hi! 👋
              </Text>
            </View>
          ) : (
            messages.map((message) => {
              const isMe = message.sender_id === user?.id;
              return (
                <View
                  key={message.id}
                  style={{
                    marginBottom: 16,
                    maxWidth: "85%",
                    alignSelf: isMe ? "flex-end" : "flex-start",
                  }}
                >
                  <View
                    style={{
                      backgroundColor: isMe ? "#FF6B9D" : theme.surface,
                      borderRadius: 20,
                      padding: 14,
                      borderBottomRightRadius: isMe ? 4 : 20,
                      borderBottomLeftRadius: isMe ? 20 : 4,
                    }}
                  >
                    <Text
                      style={{
                        fontFamily: "Nunito_400Regular",
                        fontSize: 15,
                        lineHeight: 22,
                        color: isMe ? "#1A1A1A" : theme.text,
                      }}
                    >
                      {message.content}
                    </Text>
                  </View>
                  <Text
                    style={{
                      fontFamily: "Nunito_400Regular",
                      fontSize: 11,
                      color: theme.textSecondary,
                      marginTop: 4,
                      alignSelf: isMe ? "flex-end" : "flex-start",
                    }}
                  >
                    {formatTime(message.created_at)}
                  </Text>
                </View>
              );
            })
          )}
        </ScrollView>

        {/* Input */}
        <View
          style={{
            flexDirection: "row",
            alignItems: "center",
            paddingHorizontal: 20,
            paddingVertical: 12,
            paddingBottom: insets.bottom + 12,
            borderTopWidth: 1,
            borderTopColor: theme.border,
            backgroundColor: theme.background,
            gap: 12,
          }}
        >
          <TextInput
            style={{
              flex: 1,
              backgroundColor: theme.searchBackground,
              borderRadius: 22,
              paddingHorizontal: 16,
              paddingVertical: 12,
              fontFamily: "Nunito_400Regular",
              fontSize: 15,
              color: theme.text,
              maxHeight: 100,
            }}
            value={inputText}
            onChangeText={setInputText}
            placeholder="Type a message..."
            placeholderTextColor={theme.searchPlaceholder}
            multiline
            maxLength={1000}
          />

          <TouchableOpacity
            style={{
              width: 44,
              height: 44,
              borderRadius: 22,
              backgroundColor: "#FF6B9D",
              justifyContent: "center",
              alignItems: "center",
              opacity: !inputText.trim() || sending ? 0.5 : 1,
            }}
            onPress={handleSend}
            disabled={!inputText.trim() || sending}
          >
            <Send size={20} color="#1A1A1A" />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}
