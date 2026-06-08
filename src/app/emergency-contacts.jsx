import React, { useState } from "react";
import {
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  ScrollView,
  Linking,
  Modal,
  FlatList,
  TextInput,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { StatusBar } from "expo-status-bar";
import { router } from "expo-router";
import { ArrowLeft, Phone, MapPin, Search, X } from "lucide-react-native";
import {
  useFonts,
  Nunito_400Regular,
  Nunito_500Medium,
  Nunito_600SemiBold,
} from "@expo-google-fonts/nunito";
import { Fredoka_500Medium } from "@expo-google-fonts/fredoka";
import { useTheme } from "@/utils/theme/useTheme";

const emergencyNumbers = {
  "United States": {
    police: "911",
    ambulance: "911",
    fire: "911",
    embassy: "+1-202-501-4444",
  },
  "United Kingdom": {
    police: "999",
    ambulance: "999",
    fire: "999",
    embassy: "+44-20-7499-9000",
  },
  France: {
    police: "17",
    ambulance: "15",
    fire: "18",
    embassy: "+33-1-43-12-22-22",
  },
  Germany: {
    police: "110",
    ambulance: "112",
    fire: "112",
    embassy: "+49-30-8305-0",
  },
  Japan: {
    police: "110",
    ambulance: "119",
    fire: "119",
    embassy: "+81-3-3224-5000",
  },
  Australia: {
    police: "000",
    ambulance: "000",
    fire: "000",
    embassy: "+61-2-6214-5600",
  },
  Canada: {
    police: "911",
    ambulance: "911",
    fire: "911",
    embassy: "+1-613-238-5335",
  },
  Spain: {
    police: "091",
    ambulance: "061",
    fire: "080",
    embassy: "+34-91-587-2200",
  },
  Italy: {
    police: "112",
    ambulance: "118",
    fire: "115",
    embassy: "+39-06-46741",
  },
  Thailand: {
    police: "191",
    ambulance: "1669",
    fire: "199",
    embassy: "+66-2-205-4000",
  },
  Singapore: {
    police: "999",
    ambulance: "995",
    fire: "995",
    embassy: "+65-6476-9100",
  },
  Mexico: {
    police: "911",
    ambulance: "911",
    fire: "911",
    embassy: "+52-55-5080-2000",
  },
  Brazil: {
    police: "190",
    ambulance: "192",
    fire: "193",
    embassy: "+55-61-3312-7000",
  },
  India: {
    police: "100",
    ambulance: "102",
    fire: "101",
    embassy: "+91-11-2419-8000",
  },
  China: {
    police: "110",
    ambulance: "120",
    fire: "119",
    embassy: "+86-10-8531-3000",
  },
};

const countries = Object.keys(emergencyNumbers).sort();

export default function EmergencyContactsScreen() {
  const insets = useSafeAreaInsets();
  const { theme } = useTheme();
  const [selectedCountry, setSelectedCountry] = useState("United States");
  const [showCountryPicker, setShowCountryPicker] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  const [fontsLoaded] = useFonts({
    Nunito_400Regular,
    Nunito_500Medium,
    Nunito_600SemiBold,
    Fredoka_500Medium,
  });

  const makeCall = (number) => {
    Linking.openURL(`tel:${number}`);
  };

  const getFilteredCountries = () => {
    if (!searchQuery.trim()) return countries;
    const query = searchQuery.toLowerCase();
    return countries.filter((country) => country.toLowerCase().includes(query));
  };

  const CountryPickerModal = () => {
    const filteredCountries = getFilteredCountries();

    return (
      <Modal
        visible={showCountryPicker}
        animationType="slide"
        transparent={true}
        onRequestClose={() => setShowCountryPicker(false)}
      >
        <View style={styles.modalOverlay}>
          <View
            style={[
              styles.modalContainer,
              { paddingBottom: insets.bottom + 20 },
            ]}
          >
            <View style={styles.modalHeader}>
              <Text style={styles.modalTitle}>Select Country</Text>
              <TouchableOpacity
                onPress={() => setShowCountryPicker(false)}
                style={styles.modalCloseButton}
              >
                <X size={24} color={theme.icon} />
              </TouchableOpacity>
            </View>

            <View style={styles.modalSearchContainer}>
              <Search size={20} color={theme.searchPlaceholder} />
              <TextInput
                style={styles.modalSearchInput}
                value={searchQuery}
                onChangeText={setSearchQuery}
                placeholder="Search country..."
                placeholderTextColor={theme.searchPlaceholder}
              />
              {searchQuery.length > 0 && (
                <TouchableOpacity onPress={() => setSearchQuery("")}>
                  <X size={18} color={theme.textSecondary} />
                </TouchableOpacity>
              )}
            </View>

            <FlatList
              data={filteredCountries}
              keyExtractor={(item) => item}
              showsVerticalScrollIndicator={false}
              renderItem={({ item }) => (
                <TouchableOpacity
                  style={[
                    styles.countryItem,
                    item === selectedCountry && styles.countryItemSelected,
                  ]}
                  onPress={() => {
                    setSelectedCountry(item);
                    setShowCountryPicker(false);
                    setSearchQuery("");
                  }}
                >
                  <Text style={styles.countryItemText}>{item}</Text>
                </TouchableOpacity>
              )}
            />
          </View>
        </View>
      </Modal>
    );
  };

  if (!fontsLoaded) return null;

  const numbers = emergencyNumbers[selectedCountry];

  const styles = StyleSheet.create({
    container: { flex: 1, backgroundColor: theme.background },
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
      fontFamily: "Fredoka_500Medium",
      fontSize: 20,
      color: theme.text,
    },
    scrollView: { flex: 1 },
    contentContainer: { paddingHorizontal: 24, paddingTop: 24 },
    subtitle: {
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.textSecondary,
      lineHeight: 22,
      marginBottom: 24,
    },
    countrySelector: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: 20,
      marginBottom: 24,
      borderWidth: 1,
      borderColor: theme.border,
      flexDirection: "row",
      alignItems: "center",
      justifyContent: "space-between",
    },
    countryText: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 18,
      color: theme.text,
    },
    emergencyCard: {
      backgroundColor: theme.surface,
      borderRadius: 16,
      padding: 20,
      marginBottom: 12,
      borderWidth: 1,
      borderColor: theme.border,
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
    },
    emergencyLeft: { flex: 1 },
    emergencyTitle: {
      fontFamily: "Nunito_600SemiBold",
      fontSize: 16,
      color: theme.text,
      marginBottom: 4,
    },
    emergencyNumber: {
      fontFamily: "Nunito_500Medium",
      fontSize: 20,
      color: "#FF6B9D",
    },
    callButton: {
      width: 48,
      height: 48,
      borderRadius: 24,
      backgroundColor: "#34C759",
      justifyContent: "center",
      alignItems: "center",
    },
    modalOverlay: {
      flex: 1,
      backgroundColor: "rgba(0, 0, 0, 0.5)",
      justifyContent: "flex-end",
    },
    modalContainer: {
      backgroundColor: theme.background,
      borderTopLeftRadius: 24,
      borderTopRightRadius: 24,
      maxHeight: "85%",
      paddingTop: 20,
    },
    modalHeader: {
      flexDirection: "row",
      justifyContent: "space-between",
      alignItems: "center",
      paddingHorizontal: 24,
      paddingBottom: 16,
    },
    modalTitle: {
      fontFamily: "Fredoka_500Medium",
      fontSize: 22,
      color: theme.text,
    },
    modalCloseButton: {
      width: 40,
      height: 40,
      borderRadius: 20,
      backgroundColor: theme.surface,
      justifyContent: "center",
      alignItems: "center",
    },
    modalSearchContainer: {
      flexDirection: "row",
      alignItems: "center",
      backgroundColor: theme.searchBackground,
      borderRadius: 16,
      paddingHorizontal: 16,
      paddingVertical: 12,
      marginHorizontal: 24,
      marginBottom: 16,
    },
    modalSearchInput: {
      flex: 1,
      fontFamily: "Nunito_400Regular",
      fontSize: 15,
      color: theme.text,
      marginLeft: 10,
    },
    countryItem: {
      paddingVertical: 16,
      paddingHorizontal: 24,
      borderBottomWidth: 1,
      borderBottomColor: theme.border,
    },
    countryItemSelected: { backgroundColor: theme.surface },
    countryItemText: {
      fontFamily: "Nunito_500Medium",
      fontSize: 16,
      color: theme.text,
    },
  });

  return (
    <View style={styles.container}>
      <StatusBar style={theme.statusBarStyle} />

      <View style={[styles.header, { paddingTop: insets.top + 16 }]}>
        <TouchableOpacity
          style={styles.backButton}
          onPress={() => router.back()}
        >
          <ArrowLeft size={24} color={theme.icon} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>Emergency Contacts</Text>
      </View>

      <ScrollView
        style={styles.scrollView}
        contentContainerStyle={[
          styles.contentContainer,
          { paddingBottom: insets.bottom + 20 },
        ]}
        showsVerticalScrollIndicator={false}
      >
        <Text style={styles.subtitle}>
          Important emergency numbers for your destination
        </Text>

        <TouchableOpacity
          style={styles.countrySelector}
          onPress={() => setShowCountryPicker(true)}
        >
          <Text style={styles.countryText}>{selectedCountry}</Text>
          <MapPin size={20} color={theme.icon} />
        </TouchableOpacity>

        <View style={styles.emergencyCard}>
          <View style={styles.emergencyLeft}>
            <Text style={styles.emergencyTitle}>Police</Text>
            <Text style={styles.emergencyNumber}>{numbers.police}</Text>
          </View>
          <TouchableOpacity
            style={styles.callButton}
            onPress={() => makeCall(numbers.police)}
          >
            <Phone size={24} color="#1A1A1A" />
          </TouchableOpacity>
        </View>

        <View style={styles.emergencyCard}>
          <View style={styles.emergencyLeft}>
            <Text style={styles.emergencyTitle}>Ambulance</Text>
            <Text style={styles.emergencyNumber}>{numbers.ambulance}</Text>
          </View>
          <TouchableOpacity
            style={styles.callButton}
            onPress={() => makeCall(numbers.ambulance)}
          >
            <Phone size={24} color="#1A1A1A" />
          </TouchableOpacity>
        </View>

        <View style={styles.emergencyCard}>
          <View style={styles.emergencyLeft}>
            <Text style={styles.emergencyTitle}>Fire Department</Text>
            <Text style={styles.emergencyNumber}>{numbers.fire}</Text>
          </View>
          <TouchableOpacity
            style={styles.callButton}
            onPress={() => makeCall(numbers.fire)}
          >
            <Phone size={24} color="#1A1A1A" />
          </TouchableOpacity>
        </View>

        <View style={styles.emergencyCard}>
          <View style={styles.emergencyLeft}>
            <Text style={styles.emergencyTitle}>US Embassy</Text>
            <Text style={styles.emergencyNumber}>{numbers.embassy}</Text>
          </View>
          <TouchableOpacity
            style={styles.callButton}
            onPress={() => makeCall(numbers.embassy)}
          >
            <Phone size={24} color="#1A1A1A" />
          </TouchableOpacity>
        </View>
      </ScrollView>

      <CountryPickerModal />
    </View>
  );
}
