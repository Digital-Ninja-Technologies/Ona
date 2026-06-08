import React, { useState, useRef, useEffect } from "react";
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import { ArrowLeft, Send, MessageCircle } from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";
import useHandleStreamResponse from "@/utils/useHandleStreamResponse";

export default function AIAssistantScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [messages, setMessages] = useState([
    {
      role: "assistant",
      content:
        "Hi! I'm your TravelGuide AI assistant. I can help you discover destinations, create itineraries, find the best restaurants, hotels, and answer any travel questions. Where would you like to explore?",
    },
  ]);
  const [inputText, setInputText] = useState("");
  const [streamingMessage, setStreamingMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const scrollViewRef = useRef(null);

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
  });

  const handleFinish = (message) => {
    setMessages((prev) => [...prev, { role: "assistant", content: message }]);
    setStreamingMessage("");
    setIsLoading(false);
  };

  const handleStreamResponse = useHandleStreamResponse({
    onChunk: setStreamingMessage,
    onFinish: handleFinish,
  });

  useEffect(() => {
    scrollViewRef.current?.scrollToEnd({ animated: true });
  }, [messages, streamingMessage]);

  if (!fontsLoaded) {
    return null;
  }

  const handleSend = async () => {
    if (!inputText.trim()) return;

    const userMessage = { role: "user", content: inputText.trim() };
    setMessages((prev) => [...prev, userMessage]);
    setInputText("");
    setIsLoading(true);

    try {
      const response = await fetch("/integrations/chat-gpt/conversationgpt4", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: [
            {
              role: "system",
              content:
                "You are a helpful travel assistant for GlobeMate, a travel guide app. Help users discover destinations, create itineraries, find restaurants and hotels, and answer travel questions. Be concise, friendly, and informative. When recommending destinations, mention specific places and why they're great.",
            },
            ...messages,
            userMessage,
          ],
          stream: true,
        }),
      });

      if (!response.ok) {
        throw new Error("Failed to get AI response");
      }

      handleStreamResponse(response);
    } catch (error) {
      console.error("Error with AI assistant:", error);
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content:
            "Sorry, I encountered an error. Please try again in a moment.",
        },
      ]);
      setIsLoading(false);
    }
  };

  const handleBackPress = () => {
    router.back();
  };

  const suggestedQuestions = [
    "Best destinations in Europe",
    "Create a 3-day Tokyo itinerary",
    "Where should I eat in Paris?",
    "Budget-friendly beaches",
  ];

  const styles = StyleSheet.create({
    container: {
      flex: 1,
      backgroundColor: theme.background,
    },
    header: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: 20,
      paddingBottom: 16,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
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
    headerTitle: {
      flex: 1,
    },
    title: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 20,
      color: theme.text,
    },
    subtitle: {
      fontFamily: "Nunito_400Regular",
      fontSize: 13,
      color: theme.textSecondary,
    },
    scrollView: {
      flex: 1,
    },
    messagesContainer: {
      paddingHorizontal: 20,
      paddingVertical: 20,
    },
    messageWrapper: {
      marginBottom: 16,
      maxWidth: "85%",
    },
    userMessageWrapper: {
      alignSelf: "flex-end",
    },
    assistantMessageWrapper: {
      alignSelf: "flex-start",
    },
    messageBubble: {
      borderRadius: 20,
      padding: 14,
    },
    userBubble: {
      backgroundColor: "#FF6B9D",
      borderBottomRightRadius: 4,
    },
    assistantBubble: {
      backgroundColor: theme.surface,
      borderBottomLeftRadius: 4,
    },
    messageText: {
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      lineHeight: 22,
    },
    userMessageText: {
      color: "#1A1A1A",
    },
    assistantMessageText: {
      color: theme.text,
    },
    suggestionsContainer: {
      paddingHorizontal: 20,
      paddingBottom: 16,
    },
    suggestionsTitle: {
      fontFamily: "Nunito_500Medium",
      fontSize: 13,
      color: theme.textSecondary,
      marginBottom: 12,
    },
    suggestionsRow: {
      flexDirection: "row",
      flexWrap: "wrap",
      gap: 8,
    },
    suggestionChip: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      paddingVertical: 8,
      paddingHorizontal: 14,
      borderWidth: 1,
      borderColor: theme.border,
    },
    suggestionText: {
      fontFamily: "Nunito_400Regular",
      fontSize: 13,
      color: theme.text,
    },
    inputContainer: {
      flexDirection: "row",
      alignItems: "center",
      paddingHorizontal: 20,
      paddingVertical: 12,
      borderTopWidth: 1,
      borderTopColor: theme.border,
      backgroundColor: theme.background,
      gap: 12,
    },
    input: {
      flex: 1,
      backgroundColor: theme.searchBackground,
      borderRadius: 22,
      paddingHorizontal: 16,
      paddingVertical: 12,
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.text,
      maxHeight: 100,
    },
    sendButton: {
      width: 44,
      height: 44,
      borderRadius: 22,
      backgroundColor: "#FF6B9D",
      justifyContent: "center",
      alignItems: "center",
    },
    sendButtonDisabled: {
      opacity: 0.5,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      {/* Header */}
      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity style={styles.backButton} onPress={handleBackPress}>
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>

        <View style={styles.headerTitle}>
          <Text style={styles.title}>AI Travel Assistant</Text>
          <Text style={styles.subtitle}>Powered by ChatGPT</Text>
        </View>
      </View>

      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === "ios" ? "padding" : "height"}
        keyboardVerticalOffset={0}
      >
        {/* Messages */}
        <ScrollView
          ref={scrollViewRef}
          style={styles.scrollView}
          contentContainerStyle={styles.messagesContainer}
          showsVerticalScrollIndicator={false}
        >
          {messages.map((message, index) => (
            <View
              key={index}
              style={[
                styles.messageWrapper,
                message.role === "user"
                  ? styles.userMessageWrapper
                  : styles.assistantMessageWrapper,
              ]}
            >
              <View
                style={[
                  styles.messageBubble,
                  message.role === "user"
                    ? styles.userBubble
                    : styles.assistantBubble,
                ]}
              >
                <Text
                  style={[
                    styles.messageText,
                    message.role === "user"
                      ? styles.userMessageText
                      : styles.assistantMessageText,
                  ]}
                >
                  {message.content}
                </Text>
              </View>
            </View>
          ))}

          {/* Streaming message */}
          {streamingMessage && (
            <View
              style={[styles.messageWrapper, styles.assistantMessageWrapper]}
            >
              <View style={[styles.messageBubble, styles.assistantBubble]}>
                <Text style={[styles.messageText, styles.assistantMessageText]}>
                  {streamingMessage}
                </Text>
              </View>
            </View>
          )}

          {/* Suggested questions (only show if no messages yet) */}
          {messages.length === 1 && !isLoading && (
            <View style={styles.suggestionsContainer}>
              <Text style={styles.suggestionsTitle}>Try asking:</Text>
              <View style={styles.suggestionsRow}>
                {suggestedQuestions.map((question, index) => (
                  <TouchableOpacity
                    key={index}
                    style={styles.suggestionChip}
                    onPress={() => {
                      setInputText(question);
                    }}
                  >
                    <Text style={styles.suggestionText}>{question}</Text>
                  </TouchableOpacity>
                ))}
              </View>
            </View>
          )}
        </ScrollView>

        {/* Input */}
        <View
          style={[styles.inputContainer, { paddingBottom: insets.bottom + 12 }]}
        >
          <TextInput
            style={styles.input}
            value={inputText}
            onChangeText={setInputText}
            placeholder="Ask me anything about travel..."
            placeholderTextColor={theme.searchPlaceholder}
            multiline
            maxLength={500}
          />

          <TouchableOpacity
            style={[
              styles.sendButton,
              (!inputText.trim() || isLoading) && styles.sendButtonDisabled,
            ]}
            onPress={handleSend}
            disabled={!inputText.trim() || isLoading}
          >
            <Send size={20} color="#1A1A1A" />
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </View>
  );
}
